import Deployer
import Foundation
import Models
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
    private let queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        processControllerProvider: ProcessControllerProvider,
        queueServerRunConfigurationLocation: QueueServerRunConfigurationLocation,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.processControllerProvider = processControllerProvider
        self.queueServerRunConfigurationLocation = queueServerRunConfigurationLocation
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
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
            processControllerProvider: processControllerProvider,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        try deployer.deploy(deployQueue: deployQueue)
    }
}
