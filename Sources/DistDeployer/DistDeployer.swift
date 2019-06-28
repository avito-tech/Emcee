import Deployer
import Foundation
import Models
import SSHDeployer
import TemporaryStuff

/// Class for generic usage: it deploys the provided deployable items to the provided deployment destinations, and
/// invokes the provided deployable commands.
final class DistDeployer {

    private let deploymentId: String
    private let deploymentDestinations: [DeploymentDestination]
    private let deployableItems: [DeployableItem]
    private let deployableCommands: [DeployableCommand]
    private let tempFolder: TemporaryFolder

    public init(
        deploymentId: String,
        deploymentDestinations: [DeploymentDestination],
        deployableItems: [DeployableItem],
        deployableCommands: [DeployableCommand],
        tempFolder: TemporaryFolder)
    {
        self.deploymentId = deploymentId
        self.deploymentDestinations = deploymentDestinations
        self.deployableItems = deployableItems
        self.deployableCommands = deployableCommands
        self.tempFolder = tempFolder
    }
    
    public func deploy() throws {
        let deployer = try SSHDeployer(
            sshClientType: DefaultSSHClient.self,
            deploymentId: deploymentId,
            deployables: deployableItems,
            deployableCommands: deployableCommands,
            destinations: deploymentDestinations
        )
        try deployer.deploy()
    }
}
