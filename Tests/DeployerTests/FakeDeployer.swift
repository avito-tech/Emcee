@testable import Deployer
import Foundation
import PathLib

class FakeDeployer: Deployer {
    var pathsAskedToBeDeployed: [AbsolutePath: DeployableItem] = [:]
    
    override func deployToDestinations(deployQueue: DispatchQueue, pathToDeployable: [AbsolutePath : DeployableItem]) throws {
        pathsAskedToBeDeployed = pathToDeployable
    }
}
