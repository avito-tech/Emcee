import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import RunnerTestHelpers
import TestHelpers
import Types
import XCTest

final class BucketResultRegistrarTests: XCTestCase {
    let expectedPayloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    let testingResult = TestingResultFixtures()
        .with(testEntry: TestEntryFixtures.testEntry(className: "class", methodName: "method"))
        .addingLostResult()
        .testingResult()
    lazy var buckerResultAccepter = FakeBucketResultAccepter { _, _, _ in
        throw ErrorForTestingPurposes()
    }
    lazy var registrar = BucketResultRegistrar(
        bucketResultAccepter: buckerResultAccepter,
        expectedPayloadSignature: expectedPayloadSignature
    )
    lazy var acceptedResults = [TestingResult]()

    func test__results_collector_receives_results__if_bucket_queue_accepts_results() {
        buckerResultAccepter.result = { (_: BucketId, testingResult: TestingResult, workerId: WorkerId) in
            self.acceptedResults.append(testingResult)
            return BucketQueueAcceptResult(
                dequeuedBucket: DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: BucketFixtures.createBucket(bucketId: "bucket id"),
                        enqueueTimestamp: Date(),
                        uniqueIdentifier: "doesnotmatter"
                    ),
                    workerId: workerId
                ),
                testingResultToCollect: testingResult
            )
        }
        
        let request = BucketResultPayload(
            bucketId: "bucket id",
            workerId: "worker",
            testingResult: testingResult,
            payloadSignature: expectedPayloadSignature
        )
        assertDoesNotThrow {
            try registrar.handle(payload: request)
        }
        
        assert {
            acceptedResults
        } equals: {
            [testingResult]
        }
    }
    
    func test___throws___if_accepted_throws() {
        let request = BucketResultPayload(
            bucketId: "bucket id",
            workerId: "worker",
            testingResult: testingResult,
            payloadSignature: expectedPayloadSignature
        )
        
        buckerResultAccepter.result = { (_: BucketId, testingResult: TestingResult, _: WorkerId) in
            throw ErrorForTestingPurposes()
        }
        
        assertThrows {
            try registrar.handle(payload: request)
        }
    }

    func test___throws___when_payload_signature_mismatches() {
        let registrar = BucketResultRegistrar(
            bucketResultAccepter: buckerResultAccepter,
            expectedPayloadSignature: expectedPayloadSignature
        )

        assertThrows {
            try registrar.handle(
                payload: BucketResultPayload(
                    bucketId: "bucket id",
                    workerId: "worker",
                    testingResult: testingResult,
                    payloadSignature: PayloadSignature(value: UUID().uuidString)
                )
            )
        }
    }
}

open class FakeBucketResultAccepter: BucketResultAccepter {
    public var result: (BucketId, TestingResult, WorkerId) throws -> BucketQueueAcceptResult
    
    public init(
        result: @escaping (BucketId, TestingResult, WorkerId) throws -> BucketQueueAcceptResult
    ) {
        self.result = result
    }
    
    public func accept(
        bucketId: BucketId,
        testingResult: TestingResult,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult {
        return try result(bucketId, testingResult, workerId)
    }
}
