@testable import Deployer
import Foundation
import PathLib

class FakeDeployer: Deployer {
    var pathsAskedToBeDeployed: [AbsolutePath: DeployableItem] = [:]
    
    override func deployToDestinations(pathToDeployable: [AbsolutePath: DeployableItem]) throws {
        pathsAskedToBeDeployed = pathToDeployable
    }
}
