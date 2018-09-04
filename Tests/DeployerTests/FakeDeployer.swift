import Foundation
@testable import Deployer

class FakeDeployer: Deployer {
    var urlsAskedToBeDeployed: [URL: DeployableItem] = [:]
    
    override func deployToDestinations(urlToDeployable: [URL: DeployableItem]) throws {
        urlsAskedToBeDeployed = urlToDeployable
    }
}
