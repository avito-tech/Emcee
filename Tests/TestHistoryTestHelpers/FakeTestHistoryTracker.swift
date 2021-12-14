import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels
import RunnerModels
import TestHistoryTracker

open class FakeTestHistoryTracker: TestHistoryTracker {
    public init(
        enqueuedPayloadToDequeueProvider: @escaping (WorkerId, [EnqueuedRunTestsPayload], [WorkerId]) -> EnqueuedRunTestsPayload? = {  _, _, _ in nil },
        validateWorkerIdsInWorkingCondition: @escaping ([WorkerId]) -> () = { _ in },
        acceptValidator: @escaping (TestingResult, BucketId, UInt, WorkerId) throws -> TestHistoryTrackerAcceptResult = { testingResult, _, _, _ in
            TestHistoryTrackerAcceptResult(
                testEntriesToReenqueue: [],
                testingResult: testingResult
            )
        },
        willReenqueueHandler: @escaping (BucketId, [BucketId: TestEntry]) -> () = { _, _ in }
    ) {
        self.enqueuedPayloadToDequeueProvider = enqueuedPayloadToDequeueProvider
        self.validateWorkerIdsInWorkingCondition = validateWorkerIdsInWorkingCondition
        self.acceptValidator = acceptValidator
        self.willReenqueueHandler = willReenqueueHandler
    }
    
    public var validateWorkerIdsInWorkingCondition: ([WorkerId]) -> ()
    public var enqueuedPayloadToDequeueProvider: (WorkerId, [EnqueuedRunTestsPayload], [WorkerId]) -> EnqueuedRunTestsPayload?
    public var acceptValidator: (TestingResult, BucketId, UInt, WorkerId) throws -> TestHistoryTrackerAcceptResult
    public var willReenqueueHandler: (BucketId, [BucketId: TestEntry]) -> ()
    
    public func enqueuedPayloadToDequeue(
        workerId: WorkerId,
        queue: [EnqueuedRunTestsPayload],
        workerIdsInWorkingCondition: @autoclosure () -> [WorkerId]
    ) -> EnqueuedRunTestsPayload? {
        validateWorkerIdsInWorkingCondition(workerIdsInWorkingCondition())
        return enqueuedPayloadToDequeueProvider(workerId, queue, workerIdsInWorkingCondition())
    }
    
    public func accept(
        testingResult: TestingResult,
        bucketId: BucketId,
        numberOfRetries: UInt,
        workerId: WorkerId
    ) throws -> TestHistoryTrackerAcceptResult {
        try acceptValidator(testingResult, bucketId, numberOfRetries, workerId)
    }
    
    public func willReenqueuePreviouslyFailedTests(
        whichFailedUnderBucketId oldBucketId: BucketId,
        underNewBucketIds testEntryByBucketId: [BucketId: TestEntry]
    ) {
        willReenqueueHandler(oldBucketId, testEntryByBucketId)
    }
}
