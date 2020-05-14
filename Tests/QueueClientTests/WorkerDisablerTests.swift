import Foundation
import Models
import QueueClient
import RESTMethods
import RequestSenderTestHelpers
import XCTest

final class WorkerDisablerTests: XCTestCase {
    private let workerId = WorkerId(value: "worker")
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    
    func test() throws {
        let requestSender = FakeRequestSender(
            result: WorkerDisabledResponse(workerId: workerId),
            requestSenderError: nil
        )
        
        let disabler = WorkerDisablerImpl(
            requestSender: requestSender
        )
    
        let completionHandlerCalledExpectation = expectation(description: "Completion handler has been called")
        
        disabler.disableWorker(
            workerId: workerId,
            callbackQueue: callbackQueue
        ) { (result: Either<WorkerId, Error>) in
            XCTAssertEqual(
                try? result.dematerialize(),
                self.workerId
            )
            completionHandlerCalledExpectation.fulfill()
        }
        
        wait(for: [completionHandlerCalledExpectation], timeout: 10)
    }
}
