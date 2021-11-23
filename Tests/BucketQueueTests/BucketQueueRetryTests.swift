import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import DateProviderTestHelpers
import Foundation
import QueueCommunicationTestHelpers
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers
import TestHelpers
import TestHistoryTestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import XCTest

final class BucketQueueRetryTests: XCTestCase {
    private let fixedBucketId: BucketId = "fixedBucketId"
    private lazy var uniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()

    func test___bucket_queue___gives_job_to_another_worker___if_worker_fails() throws {
        // Given
        let bucketQueue = self.bucketQueue(workerIds: [failingWorker, anotherWorker])
        
        try bucketQueue.enqueue(buckets: [bucketWithTwoRetires])
        
        // When worker fails
        try dequeueTestAndFail(bucketQueue: bucketQueue, workerId: failingWorker)
        
        // Then we give work to another worker
        XCTAssertNil(
            bucketQueue.dequeueBucket(workerCapabilities: [], workerId: failingWorker)
        )
        
        let dequeuedBucket = assertNotNil {
            bucketQueue.dequeueBucket(workerCapabilities: [], workerId: anotherWorker)
        }
        XCTAssertEqual(
            dequeuedBucket.enqueuedBucket.bucket.payload,
            bucketWithTwoRetires.payload
        )
    }
    
    func test___bucket_queue___gives_job_to_any_worker___if_all_workers_fail() throws {
        // Given
        let allWorkers = [firstWorker, secondWorker]
        let bucketQueue = self.bucketQueue(workerIds: allWorkers)
        
        try bucketQueue.enqueue(buckets: [bucketWithTwoRetires])
        
        // When all workers fail
        try allWorkers.forEach { workerId in
            try dequeueTestAndFail(bucketQueue: bucketQueue, workerId: workerId)
        }
        
        // Then any of them can take work
        let anyWorker = firstWorker
        assertNotNil {
            bucketQueue.dequeueBucket(workerCapabilities: [], workerId: anyWorker)
        }
    }
    
    func test___bucket_queue___become_depleted___after_retries() throws {
        // Given
        let bucketQueue = self.bucketQueue(workerIds: [firstWorker, secondWorker])
        
        try bucketQueue.enqueue(buckets: [bucketWithTwoRetires])
        
        // When retry limit is reached
        try [firstWorker, secondWorker, firstWorker].forEach { workerId in
            try dequeueTestAndFail(bucketQueue: bucketQueue, workerId: workerId)
        }
        
        // Then queue is empty
        let anyWorker = firstWorker
        XCTAssertNil(
            bucketQueue.dequeueBucket(workerCapabilities: [], workerId: anyWorker)
        )
    }
    
    func test___if_worker_provides_testing_result_with_missing_tests___queue_reenqueues_lost_tests() throws {
        let bucketQueue = self.bucketQueue(workerIds: [failingWorker, anotherWorker])
        let bucket = bucketWithTwoRetires
        try bucketQueue.enqueue(buckets: [bucket])
        
        _ = bucketQueue.dequeueBucket(
            workerCapabilities: [],
            workerId: failingWorker
        )
        
        let result = try bucketQueue.accept(
            bucketId: bucket.bucketId,
            testingResult: TestingResultFixtures(
                testEntry: testEntry,
                manuallyTestDestination: nil,
                unfilteredResults: [
                    TestEntryResult.lost(testEntry: testEntry)
                ]
            ).testingResult(),
            workerId: failingWorker
        )
        XCTAssertEqual(
            result.testingResultToCollect.unfilteredResults,
            [],
            "Result to collect must not contain lost test"
        )
        
        XCTAssertNil(
            bucketQueue.dequeueBucket(workerCapabilities: [], workerId: failingWorker),
            "Queue should not provide re-enqueued bucket back to a worker that lost a test previously"
        )
        
        // Queue should provide re-enqueued bucket to a worker that haven't attempted to execute the test previously
        let dequeuedBucket = assertNotNil {
            bucketQueue.dequeueBucket(workerCapabilities: [], workerId: anotherWorker)
        }
        assert { dequeuedBucket.workerId } equals: { anotherWorker }
        assert { dequeuedBucket.enqueuedBucket.bucket.payload } equals: { bucket.payload }
    }
    
    private let firstWorker: WorkerId = "firstWorker"
    private let secondWorker: WorkerId = "secondWorker"
    private let failingWorker: WorkerId = "failingWorker"
    private let anotherWorker: WorkerId = "anotherWorker"
    private let dateProvider = DateProviderFixture()
    
    private func bucketQueue(workerIds: [WorkerId]) -> BucketQueue {
        let tracker = WorkerAlivenessProviderImpl(
            knownWorkerIds: Set(workerIds),
            logger: .noOp,
            workerPermissionProvider: FakeWorkerPermissionProvider()
        )
        workerIds.forEach(tracker.didRegisterWorker)
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            dateProvider: dateProvider,
            testHistoryTracker: TestHistoryTrackerFixtures.testHistoryTracker(
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            ),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: tracker
        )
        
        return bucketQueue
    }
    
    private func dequeueTestAndFail(bucketQueue: BucketQueue, workerId: WorkerId) throws {
        guard let dequeuedBucket = bucketQueue.dequeueBucket(
            workerCapabilities: [],
            workerId: workerId
        ) else {
            failTest("Bucket is exected to be dequeued")
        }

        _ = try bucketQueue.accept(
            bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
            testingResult: testingResultFixtures.testingResult(),
            workerId: workerId
        )
    }
    
    private let testEntry = TestEntryFixtures.testEntry()
    private lazy var bucketWithTwoRetires = BucketFixtures.createBucket(
        bucketId: BucketId(uniqueIdentifierGenerator.generate()),
        testEntries: [testEntry],
        numberOfRetries: 2
    )
    
    private let testingResultFixtures: TestingResultFixtures = TestingResultFixtures()
        .addingResult(success: false)
}
