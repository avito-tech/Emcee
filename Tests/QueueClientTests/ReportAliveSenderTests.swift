import Foundation
import Models
import RESTMethods
import RequestSender
import RequestSenderTestHelpers
import QueueClient
import XCTest

final class ReportAliveSenderTests: XCTestCase {
    private let bucketId = BucketId(value: UUID().uuidString)
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    
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
        reportAliveSender.reportAlive(
            bucketIdsBeingProcessedProvider: provider(),
            workerId: "worker id",
            requestSignature: RequestSignature(value: "signature"),
            callbackQueue: callbackQueue
        ) { (result: Either<ReportAliveResponse, Error>) in
            XCTAssertEqual(
                try? result.dematerialize(),
                ReportAliveResponse.aliveReportAccepted
            )
            completionHandlerCalledExpectation.fulfill()
        }
        
        wait(for: [bucketIdsProviderCalledExpectation, completionHandlerCalledExpectation], timeout: 10)
    }
}

