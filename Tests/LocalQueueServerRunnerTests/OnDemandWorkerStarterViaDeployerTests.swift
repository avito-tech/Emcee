import Foundation
import LocalQueueServerRunner
import QueueModels
import QueueServer
import QueueServerTestHelpers
import QueueServerPortProviderTestHelpers
import SocketModels
import XCTest

final class OnDemandWorkerStarterViaDeployerTests: XCTestCase {
    private lazy var provider = FakeRemoteWorkerStarterProvider()
    private lazy var starter = FakeRemoteWorkerStarter()
    private lazy var workerId = WorkerId("workerId")
    
    func test() throws {
        provider.provider = { [starter, workerId] requestedWorkerId in
            XCTAssertEqual(requestedWorkerId, workerId)
            return starter
        }
        
        let deployer = OnDemandWorkerStarterViaDeployer(
            queueServerPortProvider: FakeQueueServerPortProvider(port: 42),
            remoteWorkerStarterProvider: provider
        )
        
        try deployer.start(workerId: workerId)
        
        XCTAssertEqual(starter.deployQueueAddress?.port, 42)
    }
}

