import Foundation
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import TestHelpers
import Types
import XCTest

final class WorkerDisablerTests: XCTestCase {
    private let workerId = WorkerId(value: "worker")
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    
    func test() throws {
        let requestSender = FakeRequestSender(
            result: WorkerDisabledResponse(workerId: workerId),
            requestSenderError: nil
        )
        
        requestSender.validateRequest = { sender in
            guard let request = sender.request as? DisableWorkerRequest else {
                self.failTest("Unexpected request")
            }
            XCTAssertEqual(request.payload?.workerId, self.workerId)
        }
        
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
