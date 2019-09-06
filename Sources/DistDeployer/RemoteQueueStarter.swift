import Deployer
import Foundation
import Models
import PathLib
import TemporaryStuff
import Version

public final class RemoteQueueStarter {
    private let deploymentId: String
    private let analyticsConfigurationLocation: AnalyticsConfigurationLocation?
    private let emceeVersionProvider: VersionProvider
    private let deploymentDestination: DeploymentDestination
    private let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation
    private let workerDestinationsLocation: WorkerDestinationsLocation
    private let tempFolder: TemporaryFolder

    public init(
        deploymentId: String,
        analyticsConfigurationLocation: AnalyticsConfigurationLocation?,
        emceeVersionProvider: VersionProvider,
        deploymentDestination: DeploymentDestination,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        workerDestinationsLocation: WorkerDestinationsLocation,
        tempFolder: TemporaryFolder
    ) {
        self.deploymentId = deploymentId
        self.analyticsConfigurationLocation = analyticsConfigurationLocation
        self.emceeVersionProvider = emceeVersionProvider
        self.deploymentDestination = deploymentDestination
        self.queueServerRunConfigurationLocation = queueServerRunConfigurationLocation
        self.workerDestinationsLocation = workerDestinationsLocation
        self.tempFolder = tempFolder
    }
    
    public func deployAndStart() throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersionProvider: emceeVersionProvider,
            remoteEmceeBinaryName: "EmceeQueueServer"
        )
        try deploy(
            deployableItems: try deployablesGenerator.deployables()
        )
        try start(
            emceeBinaryDeployableItem: try deployablesGenerator.runnerTool()
        )
    }
    
    private func deploy(deployableItems: [DeployableItem]) throws {
        let deployer = DistDeployer(
            deploymentId: deploymentId,
            deploymentDestinations: [deploymentDestination],
            deployableItems: deployableItems,
            deployableCommands: [],
            tempFolder: tempFolder
        )
        try deployer.deploy()
    }
    
    private func start(emceeBinaryDeployableItem: DeployableItem) throws {
        let launchdPlistTargetPath = "queue_server_launchd.plist"
        let launchdPlist = RemoteQueueLaunchdPlist(
            deploymentId: deploymentId,
            analyticsConfigurationLocation: analyticsConfigurationLocation,
            deploymentDestination: deploymentDestination,
            emceeDeployableItem: emceeBinaryDeployableItem,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation,
            workerDestinationsLocation: workerDestinationsLocation
        )
        let launchdPlistDeployableItem = DeployableItem(
            name: "queue_server_launchd_plist",
            files: [
                DeployableFile(
                    source: try tempFolder.createFile(
                        filename: launchdPlistTargetPath,
                        contents: try launchdPlist.plistData()
                    ),
                    destination: RelativePath(launchdPlistTargetPath)
                )
            ]
        )
        let launchctlDeployableCommands = LaunchctlDeployableCommands(
            launchdPlistDeployableItem: launchdPlistDeployableItem,
            plistFilename: launchdPlistTargetPath
        )
        let deployer = DistDeployer(
            deploymentId: deploymentId,
            deploymentDestinations: [deploymentDestination],
            deployableItems: [launchdPlistDeployableItem],
            deployableCommands: [
                launchctlDeployableCommands.forceUnloadFromBackgroundCommand(),
                launchctlDeployableCommands.forceLoadInBackgroundCommand()
            ],
            tempFolder: tempFolder
        )
        try deployer.deploy()
    }
}
