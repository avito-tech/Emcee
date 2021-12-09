import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueCommunication
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
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
        knownWorkerIds: [workerId],
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
    
    func test___when_worker_stops_processing_bucket___bucket_gets_reenqueued_into_individual_buckets_for_each_test_entry() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let testEntries = [
            TestEntry(testName: TestName(className: "class", methodName: "method1"), tags: [], caseId: nil),
            TestEntry(testName: TestName(className: "class", methodName: "method2"), tags: [], caseId: nil),
        ]
        let bucket = BucketFixtures.createBucket(
            testEntries: testEntries
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
        
        XCTAssertEqual(
            try reenqueuer.reenqueueStuckBuckets(),
            [StuckBucket(reason: .bucketLost, bucket: bucket, workerId: workerId)]
        )
        XCTAssertTrue(bucketQueueHolder.allDequeuedBuckets.isEmpty)
        
        XCTAssertEqual(
            enqueuedBuckets.map { $0.payload.testEntries },
            testEntries.map { [$0] }
        )
    }
    
    func test___when_worker_is_silent___bucket_gets_reenqueued_into_individual_buckets_for_each_test_entry() {
        workerAlivenessProvider.didRegisterWorker(workerId: workerId)
        
        let testEntries = [
            TestEntry(testName: TestName(className: "class", methodName: "method1"), tags: [], caseId: nil),
            TestEntry(testName: TestName(className: "class", methodName: "method2"), tags: [], caseId: nil),
        ]
        let bucket = BucketFixtures.createBucket(
            testEntries: testEntries
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
        
        XCTAssertEqual(
            try reenqueuer.reenqueueStuckBuckets(),
            [StuckBucket(reason: .workerIsSilent, bucket: bucket, workerId: workerId)]
        )
        XCTAssertTrue(bucketQueueHolder.allDequeuedBuckets.isEmpty)
        
        XCTAssertEqual(
            enqueuedBuckets.map { $0.payload.testEntries },
            testEntries.map { [$0] }
        )
    }
}

