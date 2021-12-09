import Foundation
import QueueClient
import QueueModels
import RESTMethods
import RequestSenderTestHelpers
import TestHelpers
import Types
import XCTest

final class JobResultsFetcherTests: XCTestCase {
    lazy var requestSender = FakeRequestSender()
    lazy var fetcher = JobResultsFetcherImpl(requestSender: requestSender)
    
    func test() {
        let jobResults = JobResults(
            jobId: "jobId",
            bucketResults: []
        )
        
        requestSender.validateRequest = { sender in
            guard let request = sender.request as? JobResultRequest else {
                failTest("Unexpected request type")
            }
            XCTAssertEqual(
                request.payload?.jobId,
                JobId("jobId")
            )
        }
        requestSender.result = JobResultsResponse(jobResults: jobResults)
        
        let expectation = XCTestExpectation(description: "callback invoked")
        
        fetcher.fetch(
            jobId: "jobId",
            callbackQueue: .global()
        ) { (response: Either<JobResults, Error>) in
            XCTAssertEqual(
                try? response.dematerialize(),
                jobResults
            )
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
}
