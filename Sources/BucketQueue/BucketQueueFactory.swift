import Foundation
import WorkerAlivenessTracker

public final class BucketQueueFactory {
    private let workerAlivenessProvider: WorkerAlivenessProvider
    private let testHistoryTracker: TestHistoryTracker
    private let checkAgainTimeInterval: TimeInterval

    public init(
        workerAlivenessProvider: WorkerAlivenessProvider,
        testHistoryTracker: TestHistoryTracker,
        checkAgainTimeInterval: TimeInterval)
    {
        self.workerAlivenessProvider = workerAlivenessProvider
        self.testHistoryTracker = testHistoryTracker
        self.checkAgainTimeInterval = checkAgainTimeInterval
    }
    
    public func createBucketQueue() -> BucketQueue {
        return BucketQueueImpl(
            workerAlivenessProvider: workerAlivenessProvider,
            testHistoryTracker: testHistoryTracker,
            checkAgainTimeInterval: checkAgainTimeInterval
        )
    }
}
