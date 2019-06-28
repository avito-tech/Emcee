import Deployer
import Foundation
import LaunchdUtils
import Models
import SSHDeployer
import TemporaryStuff

public final class RemoteQueueLaunchdPlist {
    /// Unique deployment id
    private let deploymentId: String
    /// Deployment destination where queue should start
    private let deploymentDestination: DeploymentDestination
    /// Queue server executable
    private let queueServerBinaryDeployableItem: DeployableItem
    /// A JSON file location that contains QueueServerRunConfiguration for queue server
    private let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        emceeDeployableItem: DeployableItem,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation)
    {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.queueServerBinaryDeployableItem = emceeDeployableItem
        self.queueServerRunConfigurationLocation = queueServerRunConfigurationLocation
    }
    
    public func plistData() throws -> Data {
        let containerPath = SSHDeployer.remoteContainerPath(
            forDeployable: queueServerBinaryDeployableItem,
            destination: deploymentDestination,
            deploymentId: deploymentId
        )
        let remoteQueueServerBinaryPath = SSHDeployer.remotePath(
            deployable: queueServerBinaryDeployableItem,
            file: try DeployableItemSingleFileExtractor(
                deployableItem: queueServerBinaryDeployableItem
            ).singleDeployableFile(),
            destination: deploymentDestination,
            deploymentId: deploymentId
        )
        
        let jobLabel = "ru.avito.emcee.queueServer.\(deploymentId.removingWhitespaces())"
        let launchdPlist = LaunchdPlist(
            job: LaunchdJob(
                label: jobLabel,
                programArguments: [
                    remoteQueueServerBinaryPath.pathString, "startLocalQueueServer",
                    "--queue-server-run-configuration-location", queueServerRunConfigurationLocation.resourceLocation.stringValue
                ],
                environmentVariables: [:],
                workingDirectory: containerPath.pathString,
                runAtLoad: true,
                disabled: true,
                standardOutPath: containerPath.appending(component: "stdout.log").pathString,
                standardErrorPath: containerPath.appending(component: "stderr.log").pathString,
                sockets: [:],
                inetdCompatibility: .disabled,
                sessionType: .background
            )
        )
        return try launchdPlist.createPlistData()
    }
}
