import Foundation
import QueueClient
import QueueModels
import QueueModelsTestHelpers
import RESTMethods
import RequestSender
import RequestSenderTestHelpers
import XCTest

final class BucketResultSenderTests: XCTestCase {
    private let bucketResult = BucketResult.testingResult(
        TestingResultFixtures().testingResult()
    )
    private let callbackQueue = DispatchQueue(label: "callbackQueue")
    
    func test___callback_with_result() throws {
        let sender = BucketResultSenderImpl(
            requestSender: FakeRequestSender(
                result: BucketResultAcceptResponse.bucketResultAccepted(bucketId: "bucket id"),
                requestSenderError: nil
            )
        )
        
        let callbackExpectation = expectation(description: "callback should be called")
        sender.send(
            bucketId: "bucket id",
            bucketResult: bucketResult,
            workerId: "worker id",
            payloadSignature: PayloadSignature(value: "signature"),
            callbackQueue: callbackQueue,
            completion: { result in
                XCTAssertEqual(
                    try? result.dematerialize(),
                    BucketId("bucket id")
                )
                callbackExpectation.fulfill()
            }
        )
        
        wait(for: [callbackExpectation], timeout: 10)
    }
    
    func test___callback_with_error() throws {
        let sender = BucketResultSenderImpl(
            requestSender: FakeRequestSender(result: nil, requestSenderError: RequestSenderError.noData)
        )
        
        let callbackExpectation = expectation(description: "callback should be called")
        sender.send(
            bucketId: "bucket id",
            bucketResult: bucketResult,
            workerId: "worker id",
            payloadSignature: PayloadSignature(value: "signature"),
            callbackQueue: callbackQueue,
            completion: { result in
                do {
                    _ = try result.dematerialize()
                } catch {
                    guard case RequestSenderError.noData = error else {
                        return XCTFail("Unexpected error: \(error). Error is expected to be propagated.")
                    }
                }
                callbackExpectation.fulfill()
            }
        )
        
        wait(for: [callbackExpectation], timeout: 10)
    }
}

