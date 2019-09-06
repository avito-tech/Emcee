import Deployer
import Foundation
import LaunchdUtils
import Models
import SSHDeployer
import TemporaryStuff

public final class RemoteQueueLaunchdPlist {
    /// Unique deployment id
    private let deploymentId: String
    private let analyticsConfigurationLocation: AnalyticsConfigurationLocation?
    /// Deployment destination where queue should start
    private let deploymentDestination: DeploymentDestination
    /// Queue server executable
    private let queueServerBinaryDeployableItem: DeployableItem
    /// A JSON file location that contains QueueServerRunConfiguration for queue server
    private let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation
    private let workerDestinationsLocation: WorkerDestinationsLocation

    public init(
        deploymentId: String,
        analyticsConfigurationLocation: AnalyticsConfigurationLocation?,
        deploymentDestination: DeploymentDestination,
        emceeDeployableItem: DeployableItem,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        workerDestinationsLocation: WorkerDestinationsLocation
    ) {
        self.deploymentId = deploymentId
        self.analyticsConfigurationLocation = analyticsConfigurationLocation
        self.deploymentDestination = deploymentDestination
        self.queueServerBinaryDeployableItem = emceeDeployableItem
        self.queueServerRunConfigurationLocation = queueServerRunConfigurationLocation
        self.workerDestinationsLocation = workerDestinationsLocation
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
        
        var arguments = [remoteQueueServerBinaryPath.pathString, "startLocalQueueServer"]
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            arguments += ["--analytics-configuration-location", analyticsConfigurationLocation.resourceLocation.stringValue]
        }
        arguments += ["--queue-server-run-configuration-location", queueServerRunConfigurationLocation.resourceLocation.stringValue]
        arguments += ["--worker-destinations-location", workerDestinationsLocation.resourceLocation.stringValue]
        
        let launchdPlist = LaunchdPlist(
            job: LaunchdJob(
                label: jobLabel,
                programArguments: arguments,
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
