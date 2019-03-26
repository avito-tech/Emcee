import Basic
import Deployer
import Foundation
import Models
import TempFolder

public final class RemoteQueueStarter {
    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation
    private let tempFolder: TempFolder

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        tempFolder: TempFolder)
    {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.queueServerRunConfigurationLocation = queueServerRunConfigurationLocation
        self.tempFolder = tempFolder
    }
    
    public func deployAndStart() throws {
        let deployablesGenerator = DeployablesGenerator(
            remoteAvitoRunnerPath: "EmceeQueueServer",
            pluginLocations: []
        )
        try deploy(
            deployableItems: try deployablesGenerator.deployables().values.flatMap { $0 }
        )
        try start(
            emceeBinaryDeployableItem: deployablesGenerator.runnerTool
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
                    ).pathString,
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
