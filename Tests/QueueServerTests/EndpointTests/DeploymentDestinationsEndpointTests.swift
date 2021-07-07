import DeployerTestHelpers
import QueueServer
import RequestSender
import TestHelpers
import XCTest

class DeploymentDestinationsEndpointTests: XCTestCase {
    func test() {
        let expectedDestinations = [
            DeploymentDestinationFixtures().with(host: "workerId1").build(),
            DeploymentDestinationFixtures().with(host: "workerId2").build()
        ]
        let endpoint = DeploymentDestinationsEndpoint(destinations: expectedDestinations)
        
        let response = assertDoesNotThrow {
            try endpoint.handle(payload: VoidPayload())
        }
        
        switch response {
        case .deploymentDestinations(let deployments):
            XCTAssertEqual(deployments, expectedDestinations)
        }
    }
}
