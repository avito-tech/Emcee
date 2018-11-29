import BucketQueue
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestHistoryTrackerIntegrationTests: XCTestCase {
    private let emptyResultsFixtures = TestingResultFixtures()
    private let failingWorkerId = "failingWorkerId"
    private let notFailingWorkerId = "notFailingWorkerId"
    
    private var aliveWorkers: [String] {
        return [failingWorkerId, notFailingWorkerId]
    }
    
    private let oneFailResultsFixtures = TestingResultFixtures()
        .addingResult(success: false)
    
    private lazy var noRetriesTestHistoryTracker = TestHistoryTrackerImpl(
        numberOfRetries: 0,
        testHistoryStorage: TestHistoryStorageImpl()
    )
    
    private lazy var oneRetryTestHistoryTracker = TestHistoryTrackerImpl(
        numberOfRetries: 1,
        testHistoryStorage: TestHistoryStorageImpl()
    )
    
    private lazy var mockedStorage = TestHistoryStorageMock()
    private lazy var mockedStorageTestHistoryTracker = TestHistoryTrackerImpl(
        numberOfRetries: 1,
        testHistoryStorage: mockedStorage
    )
    
    func test___accept___tells_to_accept_failures___when_retrying_is_disabled() {
        // When
        let acceptResult = noRetriesTestHistoryTracker.accept(
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
        // When
        let acceptResult = oneRetryTestHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucket: oneFailResultsFixtures.bucket,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.bucketsToReenqueue,
            [oneFailResultsFixtures.bucket],
            "If test failed once and numberOfRetries > 0 then bucket will be rescheduled"
        )
        
        XCTAssertEqual(
            acceptResult.testingResult,
            emptyResultsFixtures
                .with(bucket: oneFailResultsFixtures.bucket)
                .testingResult(),
            "If test failed once and numberOfRetries > 0 then accepted testingResult will not contain results"
        )
    }
    
    func test___accept___tells_to_accept_failures___when_maximum_numbers_of_attempts_reached() {
        // Given
        _ = oneRetryTestHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucket: oneFailResultsFixtures.bucket,
            workerId: failingWorkerId
        )
        
        // When
        let acceptResult = oneRetryTestHistoryTracker.accept(
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
        let bucketToDequeue = oneRetryTestHistoryTracker.bucketToDequeue(
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
            tracker: oneRetryTestHistoryTracker,
            workerId: failingWorkerId
        )
        
        // When
        let bucketToDequeue = oneRetryTestHistoryTracker.bucketToDequeue(
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
            tracker: oneRetryTestHistoryTracker,
            workerId: failingWorkerId
        )
        let notFailedBucket = BucketFixtures.createBucket(
            testEntries: [TestEntryFixtures.testEntry(className: "notFailed")]
        )
        
        // When
        let bucketToDequeue = oneRetryTestHistoryTracker.bucketToDequeue(
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
            tracker: oneRetryTestHistoryTracker,
            workerId: failingWorkerId
        )
        
        // When
        let bucketToDequeue = oneRetryTestHistoryTracker.bucketToDequeue(
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
