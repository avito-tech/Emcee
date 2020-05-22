import QueueCommunicationTestHelpers
import QueueServer
import XCTest

final class ToggleWorkersSharingEndpointTests: XCTestCase {
    let poller = FakeWorkerUtilizationStatusPoller()
    lazy var endpoint = ToggleWorkersSharingEndpoint(poller: poller)
    
    func test___does_not_indicate_activity() {
        XCTAssertFalse(
            endpoint.requestIndicatesActivity,
            "This endpoint should not indicate activity. Asking queue to enable worker should not prolong its lifetime."
        )
    }
        
    func test___toggle_on() {
        assertDoesNotThrow {
            try endpoint.handle(payload: .enabled)
        }
        
        XCTAssertTrue(poller.startPollingCalled)
        XCTAssertFalse(poller.stopPollingCalled)
    }
        
    func test___toggle_off() {
        assertDoesNotThrow {
            try endpoint.handle(payload: .disabled)
        }
        
        XCTAssertFalse(poller.startPollingCalled)
        XCTAssertTrue(poller.stopPollingCalled)
    }
}
