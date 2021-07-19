import QueueServer
import QueueModels
import RequestSender
import TestHelpers
import XCTest

final class WorkerIdsEndpointTests: XCTestCase {
    func test() {
        let expectedWorkerIds = Set([
            WorkerId("worker1"),
            WorkerId("worker2"),
        ])
        let endpoint = WorkerIdsEndpoint(workerIds: expectedWorkerIds)
        
        let response = assertDoesNotThrow {
            try endpoint.handle(payload: VoidPayload())
        }
        
        assert {
            response.workerIds
        } equals: {
            expectedWorkerIds
        }
    }
}
