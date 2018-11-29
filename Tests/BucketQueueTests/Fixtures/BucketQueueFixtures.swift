import Foundation
import WorkerAlivenessTracker
import BucketQueue

final class BucketQueueFixtures {
    static func bucketQueue(
        workerAlivenessProvider: WorkerAlivenessProvider,
        testHistoryTracker: TestHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker())
        -> BucketQueue
    {
        return BucketQueueFactory.create(
            workerAlivenessProvider: workerAlivenessProvider,
            testHistoryTracker: testHistoryTracker
        )
    }
}
