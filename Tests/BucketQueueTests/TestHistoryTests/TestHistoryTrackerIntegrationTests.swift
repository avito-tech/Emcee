import BucketQueue
import BucketQueueTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestHistoryTrackerIntegrationTests: XCTestCase {
    private let emptyResultsFixtures = TestingResultFixtures()
    private let failingWorkerId = "failingWorkerId"
    private let notFailingWorkerId = "notFailingWorkerId"
    
    private lazy var aliveWorkers = [failingWorkerId, notFailingWorkerId]
    
    private let oneFailResultsFixtures = TestingResultFixtures()
        .addingResult(success: false)
    
    private let testHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker()
    
    func test___accept___tells_to_accept_failures___when_retrying_is_disabled() {
        // When
        let acceptResult = testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucket: oneFailResultsFixtures.bucket,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.bucketsToReenqueue,
            [],
            "When there is no retries then bucketsToReenqueue is empty"
        )
        XCTAssertEqual(
            acceptResult.testingResult,
            oneFailResultsFixtures.testingResult(),
            "When there is no retries then testingResult is unchanged"
        )
    }
    
    func test___accept___tells_to_retry___when_retrying_is_possible() {
        let testingResultFixture = oneFailResultsFixtures.with(numberOfRetiresOfBucket: 1)
        // When
        let acceptResult = testHistoryTracker.accept(
            testingResult: testingResultFixture.testingResult(),
            bucket: testingResultFixture.bucket,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.bucketsToReenqueue,
            [testingResultFixture.bucket],
            "If test failed once and numberOfRetries > 0 then bucket will be rescheduled"
        )
        
        XCTAssertEqual(
            acceptResult.testingResult,
            emptyResultsFixtures
                .with(bucket: testingResultFixture.bucket)
                .testingResult(),
            "If test failed once and numberOfRetries > 0 then accepted testingResult will not contain results"
        )
    }
    
    func test___accept___tells_to_accept_failures___when_maximum_numbers_of_attempts_reached() {
        // Given
        _ = testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucket: oneFailResultsFixtures.bucket,
            workerId: failingWorkerId
        )
        
        // When
        let acceptResult = testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucket: oneFailResultsFixtures.bucket,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.bucketsToReenqueue,
            []
        )
        
        XCTAssertEqual(
            acceptResult.testingResult,
            oneFailResultsFixtures.testingResult()
        )
    }
    
    func test___bucketToDequeue___is_not_nil___initially() {
        // When
        let bucketToDequeue = testHistoryTracker.bucketToDequeue(
            workerId: failingWorkerId,
            queue: [oneFailResultsFixtures.bucket],
            aliveWorkers: aliveWorkers
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, oneFailResultsFixtures.bucket)
    }
    
    func test___bucketToDequeue___is_nil___for_failing_worker() {
        // Given
        failOnce(
            tracker: testHistoryTracker,
            workerId: failingWorkerId
        )
        
        // When
        let bucketToDequeue = testHistoryTracker.bucketToDequeue(
            workerId: failingWorkerId,
            queue: [oneFailResultsFixtures.bucket],
            aliveWorkers: aliveWorkers
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, nil)
    }
    
    func test___bucketToDequeue___is_not_nil___if_there_are_not_yet_failed_buckets_in_queue() {
        // Given
        failOnce(
            tracker: testHistoryTracker,
            workerId: failingWorkerId
        )
        let notFailedBucket = BucketFixtures.createBucket(
            testEntries: [TestEntryFixtures.testEntry(className: "notFailed")]
        )
        
        // When
        let bucketToDequeue = testHistoryTracker.bucketToDequeue(
            workerId: failingWorkerId,
            queue: [oneFailResultsFixtures.bucket, notFailedBucket],
            aliveWorkers: aliveWorkers
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, notFailedBucket)
    }
    
    func test___bucketToDequeue___is_not_nil___for_not_failing_worker() {
        // Given
        failOnce(
            tracker: testHistoryTracker,
            workerId: failingWorkerId
        )
        
        // When
        let bucketToDequeue = testHistoryTracker.bucketToDequeue(
            workerId: notFailingWorkerId,
            queue: [oneFailResultsFixtures.bucket],
            aliveWorkers: aliveWorkers
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, oneFailResultsFixtures.bucket)
    }
    
    private func failOnce(tracker: TestHistoryTracker, workerId: String) {
        _ = tracker.bucketToDequeue(
            workerId: failingWorkerId,
            queue: [oneFailResultsFixtures.bucket],
            aliveWorkers: aliveWorkers
        )
        _ = tracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucket: oneFailResultsFixtures.bucket,
            workerId: workerId
        )
    }
}
