import Deployer
import Foundation
import LaunchdUtils
import Models
import SSHDeployer

public final class RemoteWorkerLaunchdPlist {
    
    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let executableDeployableItem: DeployableItem
    private let queueAddress: SocketAddress
    
    public enum Error: Swift.Error, CustomStringConvertible {
        case unexpectedNumberOfFilesInEcecutableDeployable(Set<DeployableFile>)
        
        public var description: String {
            switch self {
            case .unexpectedNumberOfFilesInEcecutableDeployable(let files):
                return "Unexpected number of files in executable deployable: expected to have a single file, but \(files.count) files found: \(files)"
            }
        }
    }

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        executableDeployableItem: DeployableItem,
        queueAddress: SocketAddress)
    {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.executableDeployableItem = executableDeployableItem
        self.queueAddress = queueAddress
    }
    
    
    public func plistData() throws -> Data {
        let avitoRunnerContainerPath = SSHDeployer.remoteContainerPath(
            forDeployable: executableDeployableItem,
            destination: deploymentDestination,
            deploymentId: deploymentId
        )
        guard executableDeployableItem.files.count == 1, let emceeDeployableBinary = executableDeployableItem.files.first else {
            throw Error.unexpectedNumberOfFilesInEcecutableDeployable(executableDeployableItem.files)
        }
        let remoteAvitoRunnerPath = avitoRunnerContainerPath.appending(pathComponent: emceeDeployableBinary.destination)
        let jobLabel = "ru.avito.emcee.worker.\(deploymentId.removingWhitespaces())"
        let launchdPlist = LaunchdPlist(
            job: LaunchdJob(
                label: jobLabel,
                programArguments: [
                    remoteAvitoRunnerPath, "distWork",
                    "--queue-server", queueAddress.asString,
                    "--worker-id", deploymentDestination.identifier
                ],
                environmentVariables: [:],
                workingDirectory: avitoRunnerContainerPath,
                runAtLoad: true,
                disabled: true,
                standardOutPath: avitoRunnerContainerPath.appending(pathComponent: "stdout.log"),
                standardErrorPath: avitoRunnerContainerPath.appending(pathComponent: "stderr.log"),
                sockets: [:],
                inetdCompatibility: .disabled,
                sessionType: .background
            )
        )
        return try launchdPlist.createPlistData()
    }
    
}
