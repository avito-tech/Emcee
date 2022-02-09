import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import TestHelpers
import TestHistoryStorage
import TestHistoryTestHelpers
import TestHistoryTracker
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class TestHistoryTrackerIntegrationTests: XCTestCase {
    private let emptyResultsFixtures = TestingResultFixtures()
    private let failingWorkerId: WorkerId = "failingWorkerId"
    private let notFailingWorkerId: WorkerId = "notFailingWorkerId"
    private let fixedDate = Date()
    
    private lazy var workerIdsInWorkingCondition = [failingWorkerId, notFailingWorkerId]
    private lazy var bucketIdGenerator = HistoryTrackingUniqueIdentifierGenerator(
        delegate: UuidBasedUniqueIdentifierGenerator()
    )
    
    private lazy var testHistoryTracker = TestHistoryTrackerImpl(
        testHistoryStorage: TestHistoryStorageImpl(),
        uniqueIdentifierGenerator: bucketIdGenerator
    )

    private lazy var oneFailResultsFixtures = TestingResultFixtures()
        .addingResult(success: false)
    
    func test___accept___tells_to_accept_failures___when_retrying_is_disabled() throws {
        // When
        let acceptResult = try testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucketId: createBucketId(),
            numberOfRetries: 0,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.testEntriesToReenqueue,
            [],
            "When there is no retries then bucketsToReenqueue is empty"
        )
        XCTAssertEqual(
            acceptResult.testingResult,
            oneFailResultsFixtures.testingResult(),
            "When there is no retries then testingResult is unchanged"
        )
    }

    func test___accept___tells_to_retry___when_retrying_is_possible() throws {
        // When
        let acceptResult = try testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucketId: createBucketId(),
            numberOfRetries: 1,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.testEntriesToReenqueue,
            [
                TestEntryFixtures.testEntry(),
            ],
            "If test failed once and numberOfRetries > 0 then bucket will be rescheduled"
        )
        
        XCTAssertEqual(
            acceptResult.testingResult,
            emptyResultsFixtures.testingResult(),
            "If test failed once and numberOfRetries > 0 then accepted testingResult will not contain results"
        )
    }
    
    func test___accept___tells_to_accept_failures___when_maximum_numbers_of_attempts_reached() throws {
        // Given
        let bucketId = createBucketId()
        _ = try testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucketId: bucketId,
            numberOfRetries: 1,
            workerId: failingWorkerId
        )
        
        let newBucketId = createBucketId()
        testHistoryTracker.willReenqueuePreviouslyFailedTests(
            whichFailedUnderBucketId: bucketId,
            underNewBucketIds: [
                newBucketId: TestEntryFixtures.testEntry(),
            ]
        )
        
        // When
        let acceptResult = try testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucketId: newBucketId,
            numberOfRetries: 1,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.testEntriesToReenqueue,
            []
        )
        
        XCTAssertEqual(
            acceptResult.testingResult,
            oneFailResultsFixtures.testingResult()
        )
    }
    
    func test___accept___tells_to_retry___when_runing_same_test_from_other_bucket() throws {
        // Given
        _ = try testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucketId: createBucketId(),
            numberOfRetries: 1,
            workerId: failingWorkerId
        )
        
        let secondBucket = BucketFixtures.createBucket(
            bucketId: BucketId(value: "secondIdentifier")
        )
        
        // When
        let acceptResult = try testHistoryTracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucketId: secondBucket.bucketId,
            numberOfRetries: 1,
            workerId: failingWorkerId
        )
        
        // Then
        XCTAssertEqual(
            acceptResult.testEntriesToReenqueue,
            [
                TestEntryFixtures.testEntry(),
            ]
        )
        
        XCTAssertEqual(
            acceptResult.testingResult,
            TestingResultFixtures().testingResult()
        )
    }
    
    func test___bucketToDequeue___is_not_nil___initially() {
        // Given
        let queue = [
            EnqueuedRunTestsPayload(
                bucketId: createBucketId(),
                testDestination: TestDestinationAppleFixtures.iOSTestDestination,
                testEntries: [TestEntryFixtures.testEntry()],
                numberOfRetries: 1
            )
        ]
        
        // When
        let payloadToDequeue = testHistoryTracker.enqueuedPayloadToDequeue(
            workerId: failingWorkerId,
            queue: queue,
            workerIdsInWorkingCondition: workerIdsInWorkingCondition
        )
        
        // Then
        XCTAssertEqual(payloadToDequeue, queue[0])
    }
    
    func test___bucketToDequeue___is_nil___for_failing_worker() throws {
        // Given
        let bucketId = createBucketId()
        
        let payload = EnqueuedRunTestsPayload(
            bucketId: bucketId,
            testDestination: TestDestinationAppleFixtures.iOSTestDestination,
            testEntries: [TestEntryFixtures.testEntry()],
            numberOfRetries: 0
        )
        
        try failOnce(
            tracker: testHistoryTracker,
            bucketId: bucketId,
            workerId: failingWorkerId
        )
        
        // When
        let payloadToDequeue = testHistoryTracker.enqueuedPayloadToDequeue(
            workerId: failingWorkerId,
            queue: [
                payload,
            ],
            workerIdsInWorkingCondition: workerIdsInWorkingCondition
        )
        
        // Then
        XCTAssertEqual(payloadToDequeue, nil)
    }
    
    func test___bucketToDequeue___is_not_nil___if_there_are_not_yet_failed_buckets_in_queue() throws {
        // Given
        let bucketId = createBucketId()
        
        let payload = EnqueuedRunTestsPayload(
            bucketId: bucketId,
            testDestination: TestDestinationAppleFixtures.iOSTestDestination,
            testEntries: [TestEntryFixtures.testEntry()],
            numberOfRetries: 0
        )
        
        try failOnce(
            tracker: testHistoryTracker,
            bucketId: bucketId,
            workerId: failingWorkerId
        )
        
        let notFailedPayload = EnqueuedRunTestsPayload(
            bucketId: createBucketId(),
            testDestination: TestDestinationAppleFixtures.iOSTestDestination,
            testEntries: [TestEntryFixtures.testEntry(className: "notFailed")],
            numberOfRetries: 0
        )
        
        // When
        let payloadToDequeue = testHistoryTracker.enqueuedPayloadToDequeue(
            workerId: failingWorkerId,
            queue: [
                payload,
                notFailedPayload,
            ],
            workerIdsInWorkingCondition: workerIdsInWorkingCondition
        )
        // Then
        XCTAssertEqual(payloadToDequeue, notFailedPayload)
    }
    
    func test___bucketToDequeue___is_not_nil___for_not_failing_worker() throws {
        // Given
        let bucketId = createBucketId()
        
        let payload = EnqueuedRunTestsPayload(
            bucketId: bucketId,
            testDestination: TestDestinationAppleFixtures.iOSTestDestination,
            testEntries: [TestEntryFixtures.testEntry()],
            numberOfRetries: 0
        )
        
        try failOnce(
            tracker: testHistoryTracker,
            bucketId: bucketId,
            workerId: failingWorkerId
        )
        
        // When
        let payloadToDequeue = testHistoryTracker.enqueuedPayloadToDequeue(
            workerId: notFailingWorkerId,
            queue: [
                payload,
            ],
            workerIdsInWorkingCondition: workerIdsInWorkingCondition
        )
        
        // Then
        XCTAssertEqual(payloadToDequeue, payload)
    }
    
    private func failOnce(
        tracker: TestHistoryTracker,
        bucketId: BucketId,
        numberOfRetries: UInt = 0,
        workerId: WorkerId
    ) throws {
        _ = tracker.enqueuedPayloadToDequeue(
            workerId: workerId,
            queue: [
                EnqueuedRunTestsPayload(
                    bucketId: bucketId,
                    testDestination: TestDestinationAppleFixtures.iOSTestDestination,
                    testEntries: [TestEntryFixtures.testEntry()],
                    numberOfRetries: numberOfRetries
                ),
            ],
            workerIdsInWorkingCondition: workerIdsInWorkingCondition
        )
        
        _ = try tracker.accept(
            testingResult: oneFailResultsFixtures.testingResult(),
            bucketId: bucketId,
            numberOfRetries: numberOfRetries,
            workerId: workerId
        )
    }
    
    private func createBucketId() -> BucketId {
        BucketId(value: bucketIdGenerator.generate())
    }
}

