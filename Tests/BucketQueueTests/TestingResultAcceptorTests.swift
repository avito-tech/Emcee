import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import TestHelpers
import TestHistoryTestHelpers
import TestHistoryTracker
import XCTest

final class TestingResultAcceptorTests: XCTestCase {
    lazy var enqueuedBuckets = [Bucket]()
    lazy var bucketEnqueuer = FakeBucketEnqueuer { buckets in
        self.enqueuedBuckets.append(contentsOf: buckets)
    }
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var testHistoryTracker = FakeTestHistoryTracker()
    
    lazy var testingResultAcceptor = TestingResultAcceptorImpl(
        bucketEnqueuer: bucketEnqueuer,
        bucketQueueHolder: bucketQueueHolder,
        logger: .noOp,
        testHistoryTracker: testHistoryTracker
    )
    
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
                    testDestination: bucket.payload.testDestination,
                    unfilteredResults: bucket.payload.testEntries.map { testEntry in
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
            _ = try testingResultAcceptor.acceptTestingResult(
                dequeuedBucket: dequeuedBucket,
                testingResult: TestingResultFixtures().testingResult()
            )
        }
        
        XCTAssertEqual(
            enqueuedBuckets,
            [bucketToBeReenqueued]
        )
    }
}
