import QueueModels
import RunnerModels
import TestHistoryModels

public protocol TestHistoryStorage {
    func history(id: TestEntryHistoryId) -> TestEntryHistory
    
    // Registers attempt, returns updated history of test entry
    func registerAttempt(
        id: TestEntryHistoryId,
        testEntryResult: TestEntryResult,
        workerId: WorkerId
    ) -> TestEntryHistory
    
    func registerReenqueuedBucketId(
        testEntryHistoryId: TestEntryHistoryId,
        enqueuedBucketId: BucketId
    )
}
