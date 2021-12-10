import Deployer
import EmceeLogging
import FileSystem
import Foundation
import SSHDeployer
import Tmp
import UniqueIdentifierGenerator
import Zip

/// Class for generic usage: it deploys the provided deployable items to the provided deployment destinations, and
/// invokes the provided deployable commands.
final class DistDeployer {
    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let deployableItems: [DeployableItem]
    private let deployableCommands: [DeployableCommand]
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let zipCompressor: ZipCompressor
    
    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        deployableItems: [DeployableItem],
        deployableCommands: [DeployableCommand],
        fileSystem: FileSystem,
        logger: ContextualLogger,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        zipCompressor: ZipCompressor
    ) {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.deployableItems = deployableItems
        self.deployableCommands = deployableCommands
        self.fileSystem = fileSystem
        self.logger = logger
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.zipCompressor = zipCompressor
    }
    
    public func deploy() throws {
        let deployer = try SSHDeployer(
            sshClientType: DefaultSSHClient.self,
            deploymentId: deploymentId,
            deployables: deployableItems,
            deployableCommands: deployableCommands,
            destination: deploymentDestination,
            fileSystem: fileSystem,
            logger: logger,
            temporaryFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            zipCompressor: zipCompressor
        )
        try deployer.deploy()
    }
}
