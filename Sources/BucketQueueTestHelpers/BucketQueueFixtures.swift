import Foundation
import WorkerAlivenessTracker
import BucketQueue

public final class BucketQueueFixtures {
    public static func bucketQueue(
        workerAlivenessProvider: WorkerAlivenessProvider,
        testHistoryTracker: TestHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker(),
        checkAgainTimeInterval: TimeInterval = 30)
        -> BucketQueue
    {
        return BucketQueueFactory(
            workerAlivenessProvider: workerAlivenessProvider,
            testHistoryTracker: testHistoryTracker,
            checkAgainTimeInterval: checkAgainTimeInterval)
            .createBucketQueue()
    }
}
