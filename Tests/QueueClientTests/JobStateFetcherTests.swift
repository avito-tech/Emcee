import Foundation
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import TestHelpers
import Types
import XCTest

final class JobStateFetcherTests: XCTestCase {
    lazy var requestSender = FakeRequestSender()
    lazy var fetcher = JobStateFetcherImpl(requestSender: requestSender)
    
    func test() {
        let jobState = JobState(jobId: "jobId", queueState: .deleted)
        
        requestSender.validateRequest = { sender in
            guard let request = sender.request as? JobStateRequest else {
                self.failTest("Unexpected request type")
            }
            XCTAssertEqual(
                request.payload?.jobId,
                JobId("jobId")
            )
        }
        requestSender.result = JobStateResponse(jobState: jobState)
        
        let expectation = XCTestExpectation(description: "callback invoked")
        
        fetcher.fetch(
            jobId: "jobId",
            callbackQueue: .global()
        ) { (response: Either<JobState, Error>) in
            XCTAssertEqual(
                try? response.dematerialize(),
                jobState
            )
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
