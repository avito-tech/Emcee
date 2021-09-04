import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import TestHelpers
import TestHistoryTestHelpers
import TestHistoryTracker
import XCTest

final class SingleBucketResultAccepterTests: XCTestCase {
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var testHistoryTracker = FakeTestHistoryTracker()
    lazy var bucketEnqueuer = FakeBucketEnqueuer()
    
    lazy var accepter = SingleBucketResultAccepter(
        bucketEnqueuer: bucketEnqueuer,
        bucketQueueHolder: bucketQueueHolder,
        logger: .noOp,
        testHistoryTracker: testHistoryTracker
    )
    
    func test___accepting_result_with_unknown_id_and_worker___throws_error() {
        assertThrows {
            _ = try accepter.accept(
                bucketId: "bucketId",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: "worker"
            )
        }
    }
    
    func test___accepting_result_with_known_bucket_id_and_matching_worker_id() {
        let bucket = BucketFixtures.createBucket()
        let enqueuedBucket = EnqueuedBucket(
            bucket: bucket,
            enqueueTimestamp: Date(),
            uniqueIdentifier: "id"
        )
        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: enqueuedBucket,
            workerId: "workerId"
        )
        
        bucketQueueHolder.add(dequeuedBucket: dequeuedBucket)
        
        assertDoesNotThrow {
            _ = try accepter.accept(
                bucketId: bucket.bucketId,
                testingResult: TestingResultFixtures()
                    .with(testEntry: bucket.runTestsBucketPayload.testEntries[0])
                    .addingResult(success: true)
                    .testingResult(),
                workerId: "workerId"
            )
        }
    }
    
    func test___reports_both_original_and_additional_lost_results___and_reenqueues_lost_tests() {
        let bucket = BucketFixtures.createBucket()
        let enqueuedBucket = EnqueuedBucket(
            bucket: bucket,
            enqueueTimestamp: Date(),
            uniqueIdentifier: "id"
        )
        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: enqueuedBucket,
            workerId: "workerId"
        )
        bucketQueueHolder.add(dequeuedBucket: dequeuedBucket)
        
        let bucketToBeReenqueued = BucketFixtures.createBucket()
        
        testHistoryTracker.acceptValidator = { testingResult, _, _ in
            if testingResult.unfilteredResults.isEmpty {
                return TestHistoryTrackerAcceptResult(
                    bucketsToReenqueue: [],
                    testingResult: testingResult
                )
            }
            XCTAssertEqual(
                testingResult,
                TestingResult(
                    testDestination: bucket.runTestsBucketPayload.testDestination,
                    unfilteredResults: bucket.runTestsBucketPayload.testEntries.map { testEntry in
                        TestEntryResult.lost(testEntry: testEntry)
                    }
                )
            )
            return TestHistoryTrackerAcceptResult(
                bucketsToReenqueue: [bucketToBeReenqueued],
                testingResult: testingResult
            )
        }
        
        assertDoesNotThrow {
            _ = try accepter.accept(
                bucketId: bucket.bucketId,
                testingResult: TestingResultFixtures().testingResult(),
                workerId: "workerId"
            )
        }
        
        XCTAssertEqual(
            bucketEnqueuer.enqueuedBuckets,
            [bucketToBeReenqueued]
        )
    }
}

extension BucketQueueHolder {
    func add(dequeuedBucket: DequeuedBucket) {
        insert(enqueuedBuckets: [dequeuedBucket.enqueuedBucket], position: 0)
        replacePreviouslyEnqueuedBucket(withDequeuedBucket: dequeuedBucket)
    }
}
