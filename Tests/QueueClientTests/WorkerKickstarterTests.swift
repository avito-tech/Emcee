import Dispatch
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import TestHelpers
import Types
import XCTest

final class WorkerKickstarterTests: XCTestCase {
    private let callbackQueue = DispatchQueue(label: "callback")
    private lazy var workerId = WorkerId("workerId")
    
    func test() {
        let requestSender = FakeRequestSender(
            result: KickstartWorkerResponse(workerId: workerId),
            requestSenderError: nil
        )
        
        requestSender.validateRequest = { sender in
            guard let request = sender.request as? KickstartWorkerRequest else {
                failTest("Unexpected request")
            }
            XCTAssertEqual(request.payload?.workerId, self.workerId)
        }
        
        let kickstarter = WorkerKickstarterImpl(requestSender: requestSender)
        
        let completionHandlerCalledExpectation = expectation(description: "Completion handler has been called")
        
        kickstarter.kickstart(
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

