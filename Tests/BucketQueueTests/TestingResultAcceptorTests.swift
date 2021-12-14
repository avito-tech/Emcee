import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerModels
import RunnerTestHelpers
import TestHelpers
import TestHistoryTestHelpers
import TestHistoryTracker
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class TestingResultAcceptorTests: XCTestCase {
    lazy var enqueuedBuckets = [Bucket]()
    lazy var bucketEnqueuer = FakeBucketEnqueuer { buckets in
        self.enqueuedBuckets.append(contentsOf: buckets)
    }
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var testHistoryTracker = FakeTestHistoryTracker()
    lazy var uniqueIdentifierGenerator = HistoryTrackingUniqueIdentifierGenerator(
        delegate: UuidBasedUniqueIdentifierGenerator()
    )
    
    lazy var testingResultAcceptor = TestingResultAcceptorImpl(
        bucketEnqueuer: bucketEnqueuer,
        bucketQueueHolder: bucketQueueHolder,
        logger: .noOp,
        testHistoryTracker: testHistoryTracker,
        uniqueIdentifierGenerator: uniqueIdentifierGenerator
    )
    
    func test___reports_both_original_and_additional_lost_results___and_reenqueues_lost_tests() {
        let runIosTestsPayload = BucketFixtures.createRunIosTestsPayload()
        let bucket = BucketFixtures.createBucket(bucketPayloadContainer: .runIosTests(runIosTestsPayload))
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
        
        let acceptValidatorInvoked = XCTestExpectation()
        testHistoryTracker.acceptValidator = { testingResult, _, _, _ in
            defer {
                acceptValidatorInvoked.fulfill()
            }
            
            if testingResult.unfilteredResults.isEmpty {
                return TestHistoryTrackerAcceptResult(
                    testEntriesToReenqueue: [],
                    testingResult: testingResult
                )
            }
            XCTAssertEqual(
                testingResult,
                TestingResult(
                    testDestination: runIosTestsPayload.testDestination,
                    unfilteredResults: runIosTestsPayload.testEntries.map { testEntry in
                        TestEntryResult.lost(testEntry: testEntry)
                    }
                )
            )
            return TestHistoryTrackerAcceptResult(
                testEntriesToReenqueue: [
                    TestEntryFixtures.testEntry(),
                ],
                testingResult: testingResult
            )
        }
        
        let willReenqueueHandlerInvoked = XCTestExpectation()
        testHistoryTracker.willReenqueueHandler = { [uniqueIdentifierGenerator] bucketId, testEntryByNewBucketId in
            assert { bucketId } equals: { bucket.bucketId }
            
            XCTAssertEqual(
                testEntryByNewBucketId,
                [BucketId(uniqueIdentifierGenerator.history[0]): TestEntryFixtures.testEntry()]
            )
            
            willReenqueueHandlerInvoked.fulfill()
        }
        
        assertDoesNotThrow {
            _ = try testingResultAcceptor.acceptTestingResult(
                dequeuedBucket: dequeuedBucket,
                bucketPayloadWithTests: runIosTestsPayload,
                testingResult: TestingResultFixtures().testingResult()
            )
        }
        
        assert {
            enqueuedBuckets
        } equals: {
            [
                try bucket.with(newBucketId: BucketId(uniqueIdentifierGenerator.history[0]))
            ]
        }
        
        wait(for: [acceptValidatorInvoked, willReenqueueHandlerInvoked], timeout: 15)
    }
}
