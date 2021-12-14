import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerTestHelpers
import SimulatorPoolTestHelpers
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
    private lazy var twoTestsPayload = EnqueuedRunTestsPayload(
        bucketId: BucketId(fixedIdentifier),
        testDestination: TestDestinationFixtures.testDestination,
        testEntries: [firstTest, secondTest],
        numberOfRetries: 0
    )
    private lazy var firstTestFixtures = TestEntryHistoryFixtures(testEntry: firstTest, bucketId: twoTestsPayload.bucketId)
    private lazy var secondTestFixtures = TestEntryHistoryFixtures(testEntry: secondTest, bucketId: twoTestsPayload.bucketId)
    
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
        let payloadToDequeue = tracker.enqueuedPayloadToDequeue(
            workerId: "1",
            queue: [twoTestsPayload],
            workerIdsInWorkingCondition: ["1", "2"]
        )
        
        // Then
        XCTAssertEqual(payloadToDequeue, nil)
    }
    
    func test___bucketToDequeue___returns_bucket_that_is_not_failed___event_if_it_is_not_first_in_queue() {
        // Given
        storage.set(
            id: firstTestFixtures.testEntryHistoryId(),
            testEntryHistoryItems: [firstTestFixtures.testEntryHistoryItem(success: false, workerId: "1")]
        )
        
        // When
        let otherPayload = EnqueuedRunTestsPayload(
            bucketId: BucketId("otherBucketId"),
            testDestination: TestDestinationFixtures.testDestination,
            testEntries: [TestEntryFixtures.testEntry(className: "other")],
            numberOfRetries: 5
        )
        let payloadToDequeue = tracker.enqueuedPayloadToDequeue(
            workerId: "1",
            queue: [
                twoTestsPayload,
                otherPayload,
            ],
            workerIdsInWorkingCondition: ["1", "2"]
        )
        
        // Then
        XCTAssertEqual(payloadToDequeue, otherPayload)
    }
}
