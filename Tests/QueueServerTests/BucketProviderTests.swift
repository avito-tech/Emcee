import BucketQueue
import BucketQueueTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import QueueServer
import RESTMethods
import WorkerAlivenessProvider
import WorkerAlivenessProviderTestHelpers
import XCTest

final class BucketProviderTests: XCTestCase {
    let expectedPayloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    lazy var fetchRequest = DequeueBucketPayload(
        workerId: "worker",
        requestId: "request",
        payloadSignature: expectedPayloadSignature
    )
    let alivenessTracker = WorkerAlivenessProviderFixtures.alivenessTrackerWithAlwaysAliveResults()
    
    func test___reponse_is_empty_queue___if_queue_is_empty() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .queueIsEmpty)
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        
        let response = try bucketProvider.handle(decodedPayload: fetchRequest)
        XCTAssertEqual(response, .queueIsEmpty)
    }
    
    func test___reponse_is_check_again___if_queue_has_dequeued_buckets() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .checkAgainLater(checkAfter: 42))
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        
        let response = try bucketProvider.handle(decodedPayload: fetchRequest)
        XCTAssertEqual(response, .checkAgainLater(checkAfter: 42))
    }
    
    func test___reponse_is_worker_not_alive___if_worker_is_not_alive() throws {
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: .workerIsNotAlive)
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: bucketQueue,
            expectedPayloadSignature: expectedPayloadSignature
        )
        
        let response = try bucketProvider.handle(decodedPayload: fetchRequest)
        XCTAssertEqual(response, .workerIsNotAlive)
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
        
        let response = try bucketProvider.handle(decodedPayload: fetchRequest)
        XCTAssertEqual(response, DequeueBucketResponse.bucketDequeued(bucket: dequeuedBucket.enqueuedBucket.bucket))
    }

    func test___throws_when_request_signature_mismatches() {
        let bucketProvider = BucketProviderEndpoint(
            dequeueableBucketSource: FakeBucketQueue(fixedDequeueResult: .queueIsEmpty),
            expectedPayloadSignature: expectedPayloadSignature
        )
        XCTAssertThrowsError(
            try bucketProvider.handle(
                decodedPayload: DequeueBucketPayload(
                    workerId: "worker",
                    requestId: "request",
                    payloadSignature: PayloadSignature(value: UUID().uuidString)
                )
            ),
            "When payload signature mismatches, bucket provider endpoind should throw"
        )
    }
}
