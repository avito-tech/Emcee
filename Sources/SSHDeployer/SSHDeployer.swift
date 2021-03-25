import Deployer
import Foundation
import EmceeLogging
import PathLib
import ProcessController
import Tmp
import UniqueIdentifierGenerator

public final class SSHDeployer: Deployer {
    
    private let sshClientType: SSHClient.Type
    private let logger: ContextualLogger
    
    public init(
        sshClientType: SSHClient.Type,
        deploymentId: String,
        deployables: [DeployableItem],
        deployableCommands: [DeployableCommand],
        destination: DeploymentDestination,
        logger: ContextualLogger,
        processControllerProvider: ProcessControllerProvider,
        temporaryFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) throws {
        self.sshClientType = sshClientType
        self.logger = logger
        try super.init(
            deploymentId: deploymentId,
            deployables: deployables,
            deployableCommands: deployableCommands,
            destination: destination,
            logger: logger,
            processControllerProvider: processControllerProvider,
            temporaryFolder: temporaryFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
    
    override public func deployToDestination(
        pathToDeployable: [AbsolutePath: DeployableItem]
    ) throws {
        do {
            try deploy(pathToDeployable: pathToDeployable)
        } catch {
            log(destination, "Failed to deploy to this destination with error: \(error)")
        }
    }
    
    /**
     * Returns a remote path at remote destination which will contain all deployed contents for the given deployable.
     */
    public static func remoteContainerPath(
        forDeployable deployable: DeployableItem,
        destination: DeploymentDestination,
        deploymentId: String
    ) -> AbsolutePath {
        return AbsolutePath(destination.remoteDeploymentPath)
            .appending(components: [deploymentId, deployable.name])
    }
    
    public static func remotePath(
        deployable: DeployableItem,
        file: DeployableFile,
        destination: DeploymentDestination,
        deploymentId: String
    ) -> AbsolutePath {
        let container = remoteContainerPath(
            forDeployable: deployable,
            destination: destination,
            deploymentId: deploymentId
        )
        return container.appending(relativePath: file.destination)
    }
    
    // MARK: - Private - Deploy
    
    private func deploy(
        pathToDeployable: [AbsolutePath: DeployableItem]
    ) throws {
        log(destination, "Connecting")
        let sshClient = try self.sshClientType.init(
            host: destination.host,
            port: destination.port,
            username: destination.username,
            password: destination.password
        )
        try sshClient.connectAndAuthenticate()
        log(destination, "Connected and authenticated")
        
        try pathToDeployable.forEach { (absolutePath: AbsolutePath, deployable: DeployableItem) in
            let remoteDeploymentPath = SSHDeployer.remoteContainerPath(
                forDeployable: deployable,
                destination: destination,
                deploymentId: deploymentId
            )
            try sshClient.execute(["rm", "-rf", remoteDeploymentPath.pathString])
            try sshClient.execute(["mkdir", "-p", remoteDeploymentPath.pathString])
            let remotePackagePath = remoteDeploymentPath.appending(component: "_package.zip")
            
            try uploadFile(
                sshClient: sshClient,
                destination: destination,
                localAbsolutePath: absolutePath,
                remoteAbsolutePath: remotePackagePath
            )
            
            try deployPackageRemotely(
                sshClient: sshClient,
                destination: destination,
                deployable: deployable,
                remotePackagePath: remotePackagePath,
                remoteDeploymentPath: remoteDeploymentPath
            )
        }
        
        try invokeCommands(
            sshClient: sshClient,
            destination: destination
        )
        
        log(destination, "Finished deploying")
    }
    
    private func uploadFile(
        sshClient: SSHClient,
        destination: DeploymentDestination,
        localAbsolutePath: AbsolutePath,
        remoteAbsolutePath: AbsolutePath
    ) throws {
        log(destination, "Uploading \(localAbsolutePath) -> \(remoteAbsolutePath)")
        try sshClient.upload(localUrl: localAbsolutePath.fileUrl, remotePath: remoteAbsolutePath.pathString)
        log(destination, "Uploaded \(localAbsolutePath) -> \(remoteAbsolutePath)")
    }
    
    private func deployPackageRemotely(
        sshClient: SSHClient,
        destination: DeploymentDestination,
        deployable: DeployableItem,
        remotePackagePath: AbsolutePath,
        remoteDeploymentPath: AbsolutePath
    ) throws {
        log(destination, "Deploying '\(deployable.name)'")
        try sshClient.execute(["unzip", remotePackagePath.pathString, "-d", remoteDeploymentPath.pathString])
        log(destination, "Deployed '\(deployable.name)'")
    }
    
    // MARK: - Private - Command Invocatoin
    
    private func invokeCommands(sshClient: SSHClient, destination: DeploymentDestination) throws {
        for command in deployableCommands {
            let commandArgs: [String] = command.commandArgs.map { (arg: DeployableCommandArg) in
                switch arg {
                case let .string(value):
                    return value
                case .item(let deployableItem, let relativePath):
                    var remotePath = SSHDeployer.remoteContainerPath(
                        forDeployable: deployableItem,
                        destination: destination,
                        deploymentId: deploymentId)
                    if let additionalPath = relativePath {
                        remotePath = remotePath.appending(component: additionalPath)
                    }
                    return remotePath.pathString
                }
            }
            log(destination, "Executing command: \(command)")
            try sshClient.execute(commandArgs)
            log(destination, "Executed command")
        }
    }
    
    // MARK: - Private - Logging

    private func log(
        _ destination: DeploymentDestination,
        _ text: String,
        file: String = #file,
        line: UInt = #line
    ) {
        logger.debug("\(destination.host): \(text)", file: file, line: line)
    }
}
