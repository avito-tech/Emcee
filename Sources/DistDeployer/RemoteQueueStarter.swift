import Basic
import Deployer
import Foundation
import Models
import TempFolder
import Version

public final class RemoteQueueStarter {
    private let deploymentId: String
    private let emceeVersionProvider: VersionProvider
    private let deploymentDestination: DeploymentDestination
    private let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation
    private let tempFolder: TempFolder

    public init(
        deploymentId: String,
        emceeVersionProvider: VersionProvider,
        deploymentDestination: DeploymentDestination,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        tempFolder: TempFolder)
    {
        self.deploymentId = deploymentId
        self.emceeVersionProvider = emceeVersionProvider
        self.deploymentDestination = deploymentDestination
        self.queueServerRunConfigurationLocation = queueServerRunConfigurationLocation
        self.tempFolder = tempFolder
    }
    
    public func deployAndStart() throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersionProvider: emceeVersionProvider,
            pluginLocations: [],
            remoteEmceeBinaryName: "EmceeQueueServer"
        )
        try deploy(
            deployableItems: try deployablesGenerator.deployables().values.flatMap { $0 }
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
            deploymentDestination: deploymentDestination,
            emceeDeployableItem: emceeBinaryDeployableItem,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation
        )
        let launchdPlistDeployableItem = DeployableItem(
            name: "queue_server_launchd_plist",
            files: [
                DeployableFile(
                    source: try tempFolder.createFile(
                        filename: launchdPlistTargetPath,
                        contents: try launchdPlist.plistData()
                    ).asString,
                    destination: launchdPlistTargetPath
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
