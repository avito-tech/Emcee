import DateProvider
import Foundation
import WorkerAlivenessTracker

public final class BucketQueueFactory {
    private let checkAgainTimeInterval: TimeInterval
    private let dateProvider: DateProvider
    private let testHistoryTracker: TestHistoryTracker
    private let workerAlivenessProvider: WorkerAlivenessProvider

    public init(
        checkAgainTimeInterval: TimeInterval,
        dateProvider: DateProvider,
        testHistoryTracker: TestHistoryTracker,
        workerAlivenessProvider: WorkerAlivenessProvider)
    {
        self.checkAgainTimeInterval = checkAgainTimeInterval
        self.dateProvider = dateProvider
        self.testHistoryTracker = testHistoryTracker
        self.workerAlivenessProvider = workerAlivenessProvider
    }
    
    public func createBucketQueue() -> BucketQueue {
        return BucketQueueImpl(
            checkAgainTimeInterval: checkAgainTimeInterval,
            dateProvider: dateProvider,
            testHistoryTracker: testHistoryTracker,
            workerAlivenessProvider: workerAlivenessProvider
        )
    }
}
