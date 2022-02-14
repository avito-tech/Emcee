import Deployer
import EmceeLogging
import FileSystem
import Foundation
import PathLib
import QueueModels
import QueueServerConfiguration
import SSHDeployer
import Tmp
import UniqueIdentifierGenerator
import Zip

public final class RemoteQueueStarter {
    private let sshClientProvider: SSHClientProvider
    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let emceeVersion: Version
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let queueServerConfiguration: QueueServerConfiguration
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let zipCompressor: ZipCompressor

    public init(
        sshClientProvider: SSHClientProvider,
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        emceeVersion: Version,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        queueServerConfiguration: QueueServerConfiguration,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        zipCompressor: ZipCompressor
    ) {
        self.sshClientProvider = sshClientProvider
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.emceeVersion = emceeVersion
        self.fileSystem = fileSystem
        self.logger = logger
        self.queueServerConfiguration = queueServerConfiguration
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
        let containerPath = SSHDeployer.remoteContainerPath(
            forDeployable: emceeBinaryDeployableItem,
            destination: deploymentDestination,
            deploymentId: deploymentId
        )
        let remoteQueueServerBinaryPath = SSHDeployer.remotePath(
            deployable: emceeBinaryDeployableItem,
            file: try DeployableItemSingleFileExtractor(
                deployableItem: emceeBinaryDeployableItem
            ).singleDeployableFile(),
            destination: deploymentDestination,
            deploymentId: deploymentId
        )
        
        let queueServerConfigurationTargetPath = "queue_server_configuration.json"
        let queueServerConfigurationDirectory = "queue_server_configuration"
        let queueServerConfigurationDeployableItem = DeployableItem(
            name: queueServerConfigurationDirectory,
            files: [
                DeployableFile(
                    source: try tempFolder.createFile(
                        filename: queueServerConfigurationTargetPath,
                        contents: JSONEncoder().encode(queueServerConfiguration)
                    ),
                    destination: RelativePath(queueServerConfigurationTargetPath)
                )
            ]
        )
        
        let launchdPlistTargetPath = "queue_server_launchd.plist"
        let launchdPlist = RemoteQueueLaunchdPlist(
            deploymentId: deploymentId,
            emceeVersion: emceeVersion,
            hostname: deploymentDestination.host,
            queueServerConfigurationPath: containerPath.removingLastComponent.appending(
                queueServerConfigurationDirectory,
                queueServerConfigurationTargetPath
            ),
            containerPath: containerPath,
            remoteQueueServerBinaryPath: remoteQueueServerBinaryPath
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
            sshClientProvider: sshClientProvider,
            deploymentId: deploymentId,
            deploymentDestination: deploymentDestination,
            deployableItems: deployableItems + [
                launchdPlistDeployableItem,
                queueServerConfigurationDeployableItem
            ],
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
