import BucketQueue
import Foundation
import Models
import ModelsTestHelpers
import XCTest

final class TestHistoryTests: XCTestCase {
    private lazy var storage = TestHistoryStorageMock()
    private lazy var tracker = TestHistoryTrackerImpl(
        numberOfRetries: 1,
        testHistoryStorage: storage
    )
    
    private lazy var firstTest = TestEntryFixtures.testEntry(className: "first")
    private lazy var secondTest = TestEntryFixtures.testEntry(className: "second")
    private lazy var twoTestsBucket: Bucket = BucketFixtures.createBucket(testEntries: [firstTest, secondTest])
    private lazy var firstTestFixtures = TestEntryHistoryFixtures(testEntry: firstTest, bucket: self.twoTestsBucket)
    private lazy var secondTestFixtures = TestEntryHistoryFixtures(testEntry: secondTest, bucket: self.twoTestsBucket)
    
    func test___bucketToDequeue___returns_nil___if_some_of_tests_are_failed_in_bucket_for_worker_but_not_all() {
        // Given
        storage.set(
            id: firstTestFixtures.testEntryHistoryId(),
            testRunHistory: [firstTestFixtures.testRunHistoryItem(success: true, workerId: "1")]
        )
        storage.set(
            id: secondTestFixtures.testEntryHistoryId(),
            testRunHistory: [secondTestFixtures.testRunHistoryItem(success: false, workerId: "1")]
        )
        
        // When
        let bucketToDequeue = tracker.bucketToDequeue(
            workerId: "1",
            queue: [twoTestsBucket],
            aliveWorkers: ["1", "2"]
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, nil)
    }
    
    func test___bucketToDequeue___returns_bucket_that_is_not_failed___event_if_it_is_not_first_in_queue() {
        // Given
        storage.set(
            id: firstTestFixtures.testEntryHistoryId(),
            testRunHistory: [firstTestFixtures.testRunHistoryItem(success: false, workerId: "1")]
        )
        
        // When
        let otherBucket = BucketFixtures.createBucket(testEntries: [TestEntryFixtures.testEntry(className: "other")])
        let bucketToDequeue = tracker.bucketToDequeue(
            workerId: "1",
            queue: [twoTestsBucket, otherBucket],
            aliveWorkers: ["1", "2"]
        )
        
        // Then
        XCTAssertEqual(bucketToDequeue, otherBucket)
    }
}
