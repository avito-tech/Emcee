import Models
import QueueClient
import RequestSender
import RequestSenderTestHelpers
import RESTMethods
import TestHelpers
import XCTest

class WorkersSharingTogglerTests: XCTestCase {
    lazy var toggler = DefaultWorkersSharingToggler(timeout: 0.1, requestSender: requestSender)
    let requestSender = FakeRequestSender()
    
    func test___request_successful___does_not_throw() {
        requestSender.result = VoidPayload()
        
        assertDoesNotThrow {
            try toggler.setSharingStatus(.enabled)
        }
        let request = requestSender.request as? ToggleWorkersSharingRequest
        XCTAssertEqual(request?.payload, .enabled)
    }
    
    func test___request_unsuccessful___throws() {
        requestSender.requestSenderError = .noData
        
        assertThrows {
            try toggler.setSharingStatus(.disabled)
        }
        let request = requestSender.request as? ToggleWorkersSharingRequest
        XCTAssertEqual(request?.payload, .disabled)
    }
    
    func test___request_timeout___throws() {
        assertThrows {
            try toggler.setSharingStatus(.enabled)
        }
    }
}
