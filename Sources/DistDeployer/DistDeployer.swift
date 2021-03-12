import Deployer
import EmceeLogging
import Foundation
import ProcessController
import SSHDeployer
import Tmp
import UniqueIdentifierGenerator

/// Class for generic usage: it deploys the provided deployable items to the provided deployment destinations, and
/// invokes the provided deployable commands.
final class DistDeployer {

    private let deploymentId: String
    private let deploymentDestination: DeploymentDestination
    private let deployableItems: [DeployableItem]
    private let deployableCommands: [DeployableCommand]
    private let logger: ContextualLogger
    private let processControllerProvider: ProcessControllerProvider
    private let tempFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        deploymentId: String,
        deploymentDestination: DeploymentDestination,
        deployableItems: [DeployableItem],
        deployableCommands: [DeployableCommand],
        logger: ContextualLogger,
        processControllerProvider: ProcessControllerProvider,
        tempFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.deploymentId = deploymentId
        self.deploymentDestination = deploymentDestination
        self.deployableItems = deployableItems
        self.deployableCommands = deployableCommands
        self.logger = logger.forType(Self.self)
        self.processControllerProvider = processControllerProvider
        self.tempFolder = tempFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func deploy() throws {
        let deployer = try SSHDeployer(
            sshClientType: DefaultSSHClient.self,
            deploymentId: deploymentId,
            deployables: deployableItems,
            deployableCommands: deployableCommands,
            destination: deploymentDestination,
            logger: logger,
            processControllerProvider: processControllerProvider,
            temporaryFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        try deployer.deploy()
    }
}
