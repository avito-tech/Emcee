import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import CommonTestModelsTestHelpers
import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import TestHelpers
import Types
import XCTest

final class BucketResultRegistrarTests: XCTestCase {
    let expectedPayloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    let testingResult = TestingResultFixtures()
        .with(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "method"))
        .addingLostResult()
        .testingResult()
    lazy var bucketResult = BucketResult.testingResult(testingResult)
    lazy var buckerResultAcceptor = FakeBucketResultAcceptor { _, _, _ in
        throw ErrorForTestingPurposes()
    }
    lazy var registrar = BucketResultRegistrar(
        bucketResultAcceptor: buckerResultAcceptor,
        expectedPayloadSignature: expectedPayloadSignature
    )
    lazy var acceptedResults = [BucketResult]()
    lazy var bucketId = BucketId("bucket id")
    lazy var workerId = WorkerId("worker")

    func test__results_collector_receives_results__if_bucket_queue_accepts_results() {
        buckerResultAcceptor.result = { (_: BucketId, bucketResult: BucketResult, providedWorkerId: WorkerId) in
            self.acceptedResults.append(bucketResult)
            return BucketQueueAcceptResult(
                dequeuedBucket: DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: BucketFixtures()
                            .with(bucketId: self.bucketId)
                            .bucket(),
                        enqueueTimestamp: Date(),
                        uniqueIdentifier: "doesnotmatter"
                    ),
                    workerId: providedWorkerId
                ),
                bucketResultToCollect: bucketResult
            )
        }
        
        let request = BucketResultPayload(
            bucketId: bucketId,
            workerId: workerId,
            bucketResult: bucketResult,
            payloadSignature: expectedPayloadSignature
        )
        assertDoesNotThrow {
            try registrar.handle(payload: request)
        }
        
        assert {
            acceptedResults
        } equals: {
            [bucketResult]
        }
    }
    
    func test___throws___if_accepted_throws() {
        let request = BucketResultPayload(
            bucketId: bucketId,
            workerId: workerId,
            bucketResult: bucketResult,
            payloadSignature: expectedPayloadSignature
        )
        
        buckerResultAcceptor.result = { (_: BucketId, _: BucketResult, _: WorkerId) in
            throw ErrorForTestingPurposes()
        }
        
        assertThrows {
            try registrar.handle(payload: request)
        }
    }

    func test___throws___when_payload_signature_mismatches() {
        let registrar = BucketResultRegistrar(
            bucketResultAcceptor: buckerResultAcceptor,
            expectedPayloadSignature: expectedPayloadSignature
        )

        assertThrows {
            try registrar.handle(
                payload: BucketResultPayload(
                    bucketId: bucketId,
                    workerId: workerId,
                    bucketResult: bucketResult,
                    payloadSignature: PayloadSignature(value: UUID().uuidString)
                )
            )
        }
    }
}

open class FakeBucketResultAcceptor: BucketResultAcceptor {
    public var result: (BucketId, BucketResult, WorkerId) throws -> BucketQueueAcceptResult
    
    public init(
        result: @escaping (BucketId, BucketResult, WorkerId) throws -> BucketQueueAcceptResult
    ) {
        self.result = result
    }
    
    public func accept(
        bucketId: BucketId,
        bucketResult: BucketResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        return try result(bucketId, bucketResult, workerId)
    }
}
