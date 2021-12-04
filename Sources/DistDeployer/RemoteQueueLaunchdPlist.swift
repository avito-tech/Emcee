import Deployer
import Foundation
import LaunchdUtils
import QueueModels
import SSHDeployer
import Tmp

public final class RemoteQueueLaunchdPlist {
    /// Unique deployment id
    private let deploymentId: String
    /// Deployment destination where queue should start
    private let deploymentDestination: DeploymentDestination
    /// Emcee binary version
    private let emceeVersion: Version
    /// Queue server executable
    private let queueServerBinaryDeployableItem: DeployableItem
    /// A JSON file location that contains QueueServerConfiguration for queue server
    private let queueServerConfigurationLocation: QueueServerConfigurationLocation

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        emceeDeployableItem: DeployableItem,
        emceeVersion: Version,
        queueServerConfigurationLocation: QueueServerConfigurationLocation
    ) {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.queueServerBinaryDeployableItem = emceeDeployableItem
        self.queueServerConfigurationLocation = queueServerConfigurationLocation
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
                username: nil,
                groupname: nil,
                programArguments: [
                    remoteQueueServerBinaryPath.pathString, "startLocalQueueServer",
                    "--emcee-version", emceeVersion.value,
                    "--queue-server-configuration-location", try queueServerConfigurationLocation.resourceLocation.stringValue()
                ],
                environmentVariables: [:],
                workingDirectory: containerPath.pathString,
                runAtLoad: true,
                disabled: true,
                standardOutPath: containerPath.appending("stdout.log").pathString,
                standardErrorPath: containerPath.appending("stderr.log").pathString,
                sockets: [:],
                inetdCompatibility: .disabled,
                sessionType: .background
            )
        )
        return try launchdPlist.createPlistData()
    }
}
