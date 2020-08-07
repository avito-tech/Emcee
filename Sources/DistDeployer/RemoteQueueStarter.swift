import Deployer
import Foundation
import PathLib
import ProcessController
import QueueModels
import TemporaryStuff
import UniqueIdentifierGenerator

public final class RemoteQueueStarter {
    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let emceeVersion: Version
    private let processControllerProvider: ProcessControllerProvider
    private let queueServerConfigurationLocation: QueueServerConfigurationLocation
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        processControllerProvider: ProcessControllerProvider,
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.processControllerProvider = processControllerProvider
        self.queueServerConfigurationLocation = queueServerConfigurationLocation
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func deployAndStart() throws {
        let deployablesGenerator = DeployablesGenerator(
            emceeVersion: emceeVersion,
            remoteEmceeBinaryName: "EmceeQueueServer"
        )
        try deploy(
            deployableItems: try deployablesGenerator.deployables(),
            emceeBinaryDeployableItem: try deployablesGenerator.runnerTool()
        )
    }
    
    private func deploy(
        deployableItems: [DeployableItem],
        emceeBinaryDeployableItem: DeployableItem
    ) throws {
        let launchdPlistTargetPath = "queue_server_launchd.plist"
        let launchdPlist = RemoteQueueLaunchdPlist(
            deploymentId: deploymentId,
            deploymentDestination: deploymentDestination,
            emceeDeployableItem: emceeBinaryDeployableItem,
            emceeVersion: emceeVersion,
            queueServerConfigurationLocation: queueServerConfigurationLocation
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
            deploymentDestination: deploymentDestination,
            deployableItems: deployableItems + [launchdPlistDeployableItem],
            deployableCommands: [
                launchctlDeployableCommands.forceUnloadFromBackgroundCommand(),
                launchctlDeployableCommands.forceLoadInBackgroundCommand()
            ],
            processControllerProvider: processControllerProvider,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        try deployer.deploy()
    }
}
