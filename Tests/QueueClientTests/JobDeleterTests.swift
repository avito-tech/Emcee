import Foundation
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import TestHelpers
import Types
import XCTest

final class JobDeleterTests: XCTestCase {
    lazy var requestSender = FakeRequestSender()
    lazy var deleter = JobDeleterImpl(requestSender: requestSender)
    
    func test() {
        requestSender.validateRequest = { sender in
            guard let request = sender.request as? JobDeleteRequest else {
                failTest("Unexpected request type")
            }
            XCTAssertEqual(
                request.payload?.jobId,
                JobId("jobId")
            )
        }
        requestSender.result = JobDeleteResponse(jobId: "jobId")
        
        let expectation = XCTestExpectation(description: "callback invoked")
        
        deleter.delete(
            jobId: "jobId",
            callbackQueue: .global()
        ) { (response: Either<(), Error>) in
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
