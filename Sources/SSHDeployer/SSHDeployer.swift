import Ansi
import Deployer
import Extensions
import Foundation
import Logging
import Models
import ProcessController

public final class SSHDeployer: Deployer {
    
    private let sshClientType: SSHClient.Type
    private let maximumSimultaneousDeployOperations = 4
    
    public init(
        sshClientType: SSHClient.Type,
        deploymentId: String,
        deployables: [DeployableItem],
        deployableCommands: [DeployableCommand],
        destinations: [DeploymentDestination],
        cleanUpAutomatically: Bool = true) throws
    {
        self.sshClientType = sshClientType
        try super.init(
            deploymentId: deploymentId,
            deployables: deployables,
            deployableCommands: deployableCommands,
            destinations: destinations)
    }
    
    override public func deployToDestinations(urlToDeployable: [URL: DeployableItem]) throws {
        let syncQueue = DispatchQueue(label: "ru.avito.SSHDeployer.syncQueue")
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = maximumSimultaneousDeployOperations
        
        var destinationsFailedToDeploy = [DeploymentDestination]()
        DispatchQueue.concurrentPerform(iterations: destinations.count) { (destinationIndex: Int) in
            let destination = self.destinations[destinationIndex]
            operationQueue.addOperation {
                do {
                    try self.deploy(destination: destination, urlToDeployable: urlToDeployable)
                } catch let error {
                    syncQueue.sync { destinationsFailedToDeploy.append(destination) }
                    SSHDeployer.log(destination, "Failed to deploy to this destination with error: \(error)", color: .red)
                }
            }
        }
        
        operationQueue.waitUntilAllOperationsAreFinished()
        
        if !destinationsFailedToDeploy.isEmpty {
            throw DeploymentError.failedToDeployToDestination(destinationsFailedToDeploy)
        }
    }
    
    /**
     * Returns a remote path at remote destination which will contain all deployed contents for the given deployable.
     */
    public static func remoteContainerPath(
        forDeployable deployable: DeployableItem,
        destination: DeploymentDestination,
        deploymentId: String) -> String
    {
        let remoteDeploymentPath = destination.remoteDeploymentPath
            .appending(pathComponent: deploymentId)
            .appending(pathComponent: deployable.name)
        return remoteDeploymentPath
    }
    
    // MARK: - Private - Deploy
    
    private func deploy(destination: DeploymentDestination, urlToDeployable: [URL: DeployableItem]) throws {
        SSHDeployer.log(destination, "Connecting")
        let sshClient = try self.sshClientType.init(
            host: destination.host,
            port: destination.port,
            username: destination.username,
            password: destination.password)
        try sshClient.connectAndAuthenticate()
        SSHDeployer.log(destination, "Connected and authenticated")
        
        try urlToDeployable.forEach { (localUrl: URL, deployable: DeployableItem) in
            let remoteDeploymentPath = SSHDeployer.remoteContainerPath(
                forDeployable: deployable,
                destination: destination,
                deploymentId: deploymentId)
            try sshClient.execute(["rm", "-rf", remoteDeploymentPath])
            try sshClient.execute(["mkdir", "-p", remoteDeploymentPath])
            let remotePackagePath = remoteDeploymentPath.appending(pathComponent: "_package.zip")
            
            try uploadFile(
                sshClient: sshClient,
                destination: destination,
                localUrl: localUrl,
                remotePath: remotePackagePath)
            
            try deployPackageRemotely(
                sshClient: sshClient,
                destination: destination,
                deployable: deployable,
                remotePackagePath: remotePackagePath,
                remoteDeploymentPath: remoteDeploymentPath)
            
            try invokeCommands(sshClient: sshClient, destination: destination)
        }
    }
    
    private func uploadFile(
        sshClient: SSHClient,
        destination: DeploymentDestination,
        localUrl: URL,
        remotePath: String) throws
    {
        SSHDeployer.log(destination, "Uploading \(localUrl.path) -> \(remotePath)")
        try sshClient.upload(localUrl: localUrl, remotePath: remotePath)
    }
    
    private func deployPackageRemotely(
        sshClient: SSHClient,
        destination: DeploymentDestination,
        deployable: DeployableItem,
        remotePackagePath: String,
        remoteDeploymentPath: String) throws
    {
        SSHDeployer.log(destination, "Deploying '\(deployable.name)'")
        try sshClient.execute(["unzip", remotePackagePath, "-d", remoteDeploymentPath])
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
                        remotePath = remotePath.appending(pathComponent: additionalPath)
                    }
                    return remotePath
                }
            }
            try sshClient.execute(commandArgs)
        }
    }
    
    // MARK: - Private - Logging

    private static func log(_ destination: DeploymentDestination, _ text: String, color: ConsoleColor = .none) {
        Logging.log("\(destination.host): \(text)", color: color)
    }
}
