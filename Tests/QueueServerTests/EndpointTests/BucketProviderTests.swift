import BucketQueue
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import QueueServer
import RESTMethods
import RunnerTestHelpers
import WorkerAlivenessProvider
import XCTest

final class BucketProviderTests: XCTestCase {
    lazy var expectedPayloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    lazy var fetchRequest = DequeueBucketPayload(
        workerId: "worker",
        requestId: "request",
        payloadSignature: expectedPayloadSignature
    )
    lazy var alivenessTracker = WorkerAlivenessProviderImpl(knownWorkerIds: ["worker"])
    
    func test___does_not_indicate_activity() {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .queueIsEmpty)
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        XCTAssertFalse(
            bucketProvider.requestIndicatesActivity,
            "This endpoint should not indicate activity: workers always fetch buckets, even if queue is empty. This should not prolong queue lifetime."
        )
    }
    
    func test___reponse_is_empty_queue___if_queue_is_empty() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .queueIsEmpty)
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        
        let response = try bucketProvider.handle(payload: fetchRequest)
        XCTAssertEqual(response, .queueIsEmpty)
    }
    
    func test___reponse_is_check_again___if_queue_has_dequeued_buckets() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .checkAgainLater(checkAfter: 42))
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        
        let response = try bucketProvider.handle(payload: fetchRequest)
        XCTAssertEqual(response, .checkAgainLater(checkAfter: 42))
    }
    
    func test___reponse_is_worker_not_registered___if_worker_is_not_registered() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .workerIsNotRegistered)
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        
        let response = try bucketProvider.handle(payload: fetchRequest)
        XCTAssertEqual(response, .workerIsNotRegistered)
    }
    
    func test___reponse_has_dequeued_bucket___if_queue_has_enqueued_buckets() throws {
        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(
                bucket: BucketFixtures.createBucket(
                    testEntries: [TestEntryFixtures.testEntry(className: "class", methodName: "test")]),
                enqueueTimestamp: Date(),
                uniqueIdentifier: "identifier"
            ),
            workerId: "worker",
            requestId: "request")
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .dequeuedBucket(dequeuedBucket))
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        
        let response = try bucketProvider.handle(payload: fetchRequest)
        XCTAssertEqual(response, DequeueBucketResponse.bucketDequeued(bucket: dequeuedBucket.enqueuedBucket.bucket))
    }

    func test___throws_when_request_signature_mismatches() {
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: FakeBucketQueue(fixedDequeueResult: .queueIsEmpty),
            expectedPayloadSignature: expectedPayloadSignature
        )
        XCTAssertThrowsError(
            try bucketProvider.handle(
                payload: DequeueBucketPayload(
                    workerId: "worker",
                    requestId: "request",
                    payloadSignature: PayloadSignature(value: UUID().uuidString)
                )
            ),
            "When payload signature mismatches, bucket provider endpoind should throw"
        )
    }
}
