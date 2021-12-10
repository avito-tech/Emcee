import Deployer
import EmceeLogging
import FileSystem
import Foundation
import PathLib
import QueueModels
import Tmp
import UniqueIdentifierGenerator
import Zip

public final class RemoteQueueStarter {
    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let emceeVersion: Version
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let queueServerConfigurationLocation: QueueServerConfigurationLocation
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let zipCompressor: ZipCompressor

    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        queueServerConfigurationLocation: QueueServerConfigurationLocation,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        zipCompressor: ZipCompressor
    ) {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.fileSystem = fileSystem
        self.logger = logger
        self.queueServerConfigurationLocation = queueServerConfigurationLocation
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.zipCompressor = zipCompressor
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
            fileSystem: fileSystem,
            logger: logger,
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            zipCompressor: zipCompressor
        )
        try deployer.deploy()
    }
}
