import Dispatch
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import TestHelpers
import Types
import XCTest

final class WorkerEnablerTests: XCTestCase {
    private lazy var enabler = WorkerEnablerImpl(requestSender: requestSender)
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    private let expectation = XCTestExpectation(description: "Response provided")
    private let requestSender = FakeRequestSender()
    private let workerId: WorkerId = "workerId"
    
    func test___success_scenario() {
        requestSender.result = WorkerEnabledResponse(workerId: self.workerId)
        
        requestSender.validateRequest = { sender in
            guard let enableRequest = sender.request as? EnableWorkerRequest else {
                failTest("Unexpected request")
            }
            
            XCTAssertEqual(enableRequest.payload?.workerId, self.workerId)
        }
        
        enabler.enableWorker(workerId: workerId, callbackQueue: callbackQueue) { (response: Either<WorkerId, Error>) in
            XCTAssertEqual(try? response.dematerialize(), self.workerId)
            self.expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 15)
    }
    
    func test___error_scenario() {
        requestSender.requestSenderError = .noData
        
        enabler.enableWorker(workerId: workerId, callbackQueue: callbackQueue) { (response: Either<WorkerId, Error>) in
            XCTAssertTrue(response.isError)
            self.expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5)
    }
}
