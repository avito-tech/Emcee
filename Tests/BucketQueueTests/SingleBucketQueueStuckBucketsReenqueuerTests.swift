import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueCommunication
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import TestHelpers
import WorkerAlivenessProvider
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class SingleBucketQueueStuckBucketsReenqueuerTests: XCTestCase {
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var enqueuedBuckets = [Bucket]()
    lazy var bucketEnqueuer = FakeBucketEnqueuer { buckets in
        self.enqueuedBuckets.append(contentsOf: buckets)
    }
    lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator()
    lazy var workerAlivenessProvider = WorkerAlivenessProviderImpl(
        logger: .noOp,
        workerPermissionProvider: workerPermissionProvider
    )
    lazy var workerPermissionProvider = FakeWorkerPermissionProvider()
    lazy var workerId = WorkerId("workerId")

    lazy var reenqueuer = SingleBucketQueueStuckBucketsReenqueuer(
        bucketEnqueuer: bucketEnqueuer,
        bucketQueueHolder: bucketQueueHolder,
        logger: .noOp,
        workerAlivenessProvider: workerAlivenessProvider,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    
    func test___when_no_stuck_buckets___nothing_reenqueued() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let bucket = BucketFixtures.createBucket()
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [bucket.bucketId], workerId: workerId)
        
        bucketQueueHolder.add(
            dequeuedBucket: DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket,
                    enqueueTimestamp: Date(),
                    uniqueIdentifier: "id"
                ),
                workerId: workerId
            )
        )
        
        XCTAssertTrue(try reenqueuer.reenqueueStuckBuckets().isEmpty)
        XCTAssertTrue(enqueuedBuckets.isEmpty)
    }
    
    func test___when_worker_stops_processing_bucket___bucket_gets_reenqueued() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let testEntries = [
            TestEntry(testName: TestName(className: "class", methodName: "method1"), tags: [], caseId: nil),
            TestEntry(testName: TestName(className: "class", methodName: "method2"), tags: [], caseId: nil),
        ]
        let runAppleTestsPayload = BucketFixtures.createrunAppleTestsPayload(
            testEntries: testEntries
        )
        let bucket = BucketFixtures.createBucket(
            bucketPayloadContainer: .runAppleTests(runAppleTestsPayload)
        )
        workerAlivenessProvider.set(bucketIdsBeingProcessed: [], workerId: workerId)
        
        bucketQueueHolder.add(
            dequeuedBucket: DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket,
                    enqueueTimestamp: Date(),
                    uniqueIdentifier: "id"
                ),
                workerId: workerId
            )
        )
        
        assert {
            try reenqueuer.reenqueueStuckBuckets()
        } equals: {
            [StuckBucket(reason: .bucketLost, bucket: bucket, workerId: workerId)]
        }
        assertTrue { bucketQueueHolder.allDequeuedBuckets.isEmpty }
        
        assert { enqueuedBuckets.count } equals: { 1 }
            
        assert { enqueuedBuckets[0].payloadContainer } equals: {
            .runAppleTests(runAppleTestsPayload)
        }
    }
    
    func test___when_worker_is_silent___bucket_gets_reenqueued() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let testEntries = [
            TestEntry(testName: TestName(className: "class", methodName: "method1"), tags: [], caseId: nil),
            TestEntry(testName: TestName(className: "class", methodName: "method2"), tags: [], caseId: nil),
        ]
        let runAppleTestsPayload = BucketFixtures.createrunAppleTestsPayload(
            testEntries: testEntries
        )
        let bucket = BucketFixtures.createBucket(
            bucketPayloadContainer: .runAppleTests(runAppleTestsPayload)
        )
        workerAlivenessProvider.setWorkerIsSilent(workerId: workerId)
        
        bucketQueueHolder.add(
            dequeuedBucket: DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: bucket,
                    enqueueTimestamp: Date(),
                    uniqueIdentifier: "id"
                ),
                workerId: workerId
            )
        )
        
        assert {
            try reenqueuer.reenqueueStuckBuckets()
        } equals: {
            [StuckBucket(reason: .workerIsSilent, bucket: bucket, workerId: workerId)]
        }
        
        assert { enqueuedBuckets.count } equals: { 1 }
        
        assert { enqueuedBuckets[0].payloadContainer } equals: {
            .runAppleTests(runAppleTestsPayload)
        }
    }
}

