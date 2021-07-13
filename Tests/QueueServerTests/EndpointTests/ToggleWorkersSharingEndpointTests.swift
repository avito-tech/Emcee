import QueueCommunicationTestHelpers
import QueueServer
import RESTMethods
import TestHelpers
import XCTest

final class ToggleWorkersSharingEndpointTests: XCTestCase {
    let poller = FakeAutoupdatingWorkerPermissionProvider()
    lazy var endpoint = ToggleWorkersSharingEndpoint(autoupdatingWorkerPermissionProvider: poller)
    
    func test___does_not_indicate_activity() {
        XCTAssertFalse(
            endpoint.requestIndicatesActivity,
            "This endpoint should not indicate activity. Asking queue to enable worker should not prolong its lifetime."
        )
    }
        
    func test___toggle_on() {
        assertDoesNotThrow {
            try endpoint.handle(payload: ToggleWorkersSharingPayload(status: .enabled))
        }
        
        XCTAssertTrue(poller.startUpdatingCalled)
        XCTAssertFalse(poller.stopUpdatingCalled)
    }
        
    func test___toggle_off() {
        assertDoesNotThrow {
            try endpoint.handle(payload: ToggleWorkersSharingPayload(status: .disabled))
        }
        
        XCTAssertFalse(poller.startUpdatingCalled)
        XCTAssertTrue(poller.stopUpdatingCalled)
    }
}
