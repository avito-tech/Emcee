import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueModelsTestHelpers
import RunnerTestHelpers
import TestHistoryTestHelpers
import TestHistoryTracker
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class TestHistoryTests: XCTestCase {
    private let storage = TestHistoryStorageMock()
    private lazy var tracker = TestHistoryTrackerImpl(
        testHistoryStorage: storage,
        uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator()
    )
    private let fixedDate = Date()
    private let fixedIdentifier = "identifier"
    private let firstTest = TestEntryFixtures.testEntry(className: "first")
    private let secondTest = TestEntryFixtures.testEntry(className: "second")
    private lazy var twoTestsBucket: EnqueuedBucket = EnqueuedBucket(
        bucket: BucketFixtures.createBucket(testEntries: [firstTest, secondTest]),
        enqueueTimestamp: fixedDate,
        uniqueIdentifier: fixedIdentifier
    )
    private lazy var firstTestFixtures = TestEntryHistoryFixtures(testEntry: firstTest, bucket: twoTestsBucket.bucket)
    private lazy var secondTestFixtures = TestEntryHistoryFixtures(testEntry: secondTest, bucket: twoTestsBucket.bucket)
    
    func test___bucketToDequeue___returns_nil___if_some_of_tests_are_failed_in_bucket_for_worker_but_not_all() {
        // Given
        storage.set(
            id: firstTestFixtures.testEntryHistoryId(),
            testEntryHistoryItems: [firstTestFixtures.testEntryHistoryItem(success: true, workerId: "1")]
        )
        storage.set(
            id: secondTestFixtures.testEntryHistoryId(),
            testEntryHistoryItems: [secondTestFixtures.testEntryHistoryItem(success: false, workerId: "1")]
        )
        
        // When
        let bucketToDequeue = tracker.bucketToDequeue(
            workerId: "1",
            queue: [twoTestsBucket],
            workerIdsInWorkingCondition: ["1", "2"]
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, nil)
    }
    
    func test___bucketToDequeue___returns_bucket_that_is_not_failed___event_if_it_is_not_first_in_queue() {
        // Given
        storage.set(
            id: firstTestFixtures.testEntryHistoryId(),
            testEntryHistoryItems: [firstTestFixtures.testEntryHistoryItem(success: false, workerId: "1")]
        )
        
        // When
        let otherBucket = EnqueuedBucket(
            bucket: BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "other")]),
            enqueueTimestamp: fixedDate,
            uniqueIdentifier: fixedIdentifier
        )
        let bucketToDequeue = tracker.bucketToDequeue(
            workerId: "1",
            queue: [twoTestsBucket, otherBucket],
            workerIdsInWorkingCondition: ["1", "2"]
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, otherBucket)
    }
}
