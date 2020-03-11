import Deployer
import Foundation
import Models
import PathLib
import TemporaryStuff

public final class RemoteQueueStarter {
    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let emceeVersion: Version
    private let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation
    private let tempFolder: TemporaryFolder

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        tempFolder: TemporaryFolder
    ) {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.queueServerRunConfigurationLocation = queueServerRunConfigurationLocation
        self.tempFolder = tempFolder
    }
    
    public func deployAndStart(deployQueue: DispatchQueue) throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersion: emceeVersion,
            remoteEmceeBinaryName: "EmceeQueueServer"
        )
        try deploy(
            deployQueue: deployQueue,
            deployableItems: try deployablesGenerator.deployables(),
            emceeBinaryDeployableItem: try deployablesGenerator.runnerTool()
        )
    }
    
    private func deploy(
        deployQueue: DispatchQueue,
        deployableItems: [DeployableItem],
        emceeBinaryDeployableItem: DeployableItem
    ) throws {
        let launchdPlistTargetPath = "queue_server_launchd.plist"
        let launchdPlist = RemoteQueueLaunchdPlist(
            deploymentId: deploymentId,
            deploymentDestination: deploymentDestination,
            emceeDeployableItem: emceeBinaryDeployableItem,
            emceeVersion: emceeVersion,
            queueServerRunConfigurationLocation: queueServerRunConfigurationLocation
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
            deployableItems: deployableItems + [launchdPlistDeployableItem],
            deployableCommands: [
                launchctlDeployableCommands.forceUnloadFromBackgroundCommand(),
                launchctlDeployableCommands.forceLoadInBackgroundCommand()
            ],
            tempFolder: tempFolder
        )
        try deployer.deploy(deployQueue: deployQueue)
    }
}
