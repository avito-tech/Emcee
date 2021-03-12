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
import WorkerAlivenessProvider
import WorkerCapabilities
import WorkerCapabilitiesModels
import XCTest

final class BucketProviderTests: XCTestCase {
    lazy var expectedPayloadSignature = PayloadSignature(value: "expectedPayloadSignature")
    lazy var fetchRequest = DequeueBucketPayload(
        payloadSignature: expectedPayloadSignature,
        workerCapabilities: [],
        workerId: "worker"
    )
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        knownWorkerIds: ["worker"],
        logger: .noOp,
        workerPermissionProvider: FakeWorkerPermissionProvider()
    )
    lazy var workerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    
    func test___does_not_indicate_activity() {
        let bucketProvider = createEndpoint()
        
        XCTAssertFalse(
            bucketProvider.requestIndicatesActivity,
            "This endpoint should not indicate activity: workers always fetch buckets, even if queue is empty. This should not prolong queue lifetime."
        )
    }
    
    func test___reponse_is_check_again___if_queue_dequeues_nil() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: fetchRequest.workerId)
        
        let bucketProvider = createEndpoint()
        
        let response = try bucketProvider.handle(payload: fetchRequest)
        XCTAssertEqual(response, .checkAgainLater(checkAfter: 42))
    }
    
    func test___reponse_is_worker_not_registered___if_worker_is_not_registered() throws {
        let bucketProvider = createEndpoint()
        
        assertThrows {
             _ = try bucketProvider.handle(payload: fetchRequest)
        }
    }
    
    func test___reponse_has_dequeued_bucket___if_queue_has_enqueued_buckets() throws {
        workerAlivenessProvider.didRegisterWorker(workerId: fetchRequest.workerId)
        
        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(
                bucket: BucketFixtures.createBucket(
                    testEntries: [TestEntryFixtures.testEntry(className: "class", methodName: "test")]),
                enqueueTimestamp: Date(),
                uniqueIdentifier: "identifier"
            ),
            workerId: "worker"
        )
        
        let bucketProvider = createEndpoint(dequeuedBucket: dequeuedBucket)
        
        let response = try bucketProvider.handle(payload: fetchRequest)
        XCTAssertEqual(
            response,
            DequeueBucketResponse.bucketDequeued(bucket: dequeuedBucket.enqueuedBucket.bucket)
        )
    }

    func test___throws_when_request_signature_mismatches() {
        let bucketProvider = createEndpoint()
        XCTAssertThrowsError(
            try bucketProvider.handle(
                payload: DequeueBucketPayload(
                    payloadSignature: PayloadSignature(value: UUID().uuidString),
                    workerCapabilities: [],
                    workerId: "worker"
                )
            ),
            "When payload signature mismatches, bucket provider endpoind should throw"
        )
    }
    
    private func createEndpoint(
        dequeuedBucket: DequeuedBucket? = nil
    ) -> BucketProviderEndpoint {
        BucketProviderEndpoint(
            checkAfter: 42,
            dequeueableBucketSource: FakeBucketQueue(fixedDequeuedBucket: dequeuedBucket),
            expectedPayloadSignature: expectedPayloadSignature,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
    }
}
