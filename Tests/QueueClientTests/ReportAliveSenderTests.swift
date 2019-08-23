import Foundation
import Models
import RESTMethods
import RequestSender
import RequestSenderTestHelpers
import QueueClient
import XCTest

final class ReportAliveSenderTests: XCTestCase {
    let bucketId = BucketId(value: UUID().uuidString)
    
    func test() throws {
        let requestSender = FakeRequestSender(
            result: ReportAliveResponse.aliveReportAccepted,
            requestSenderError: nil
        )
        let reportAliveSender = ReportAliveSenderImpl(
            requestSender: requestSender
        )
        
        let bucketIdsProviderCalledExpectation = expectation(description: "Bucket Ids provider used")
        let provider: () -> Set<BucketId> = {
            bucketIdsProviderCalledExpectation.fulfill()
            return Set([self.bucketId])
        }

        let completionHandlerCalledExpectation = expectation(description: "Completion handler has been called")
        try reportAliveSender.reportAlive(
            bucketIdsBeingProcessedProvider: provider(),
            workerId: "worker id",
            requestSignature: RequestSignature(value: "signature")
        ) { (result: Either<ReportAliveResponse, RequestSenderError>) in
            XCTAssertEqual(
                try? result.dematerialize(),
                ReportAliveResponse.aliveReportAccepted
            )
            completionHandlerCalledExpectation.fulfill()
        }
        
        wait(for: [bucketIdsProviderCalledExpectation, completionHandlerCalledExpectation], timeout: 10)
    }
}
