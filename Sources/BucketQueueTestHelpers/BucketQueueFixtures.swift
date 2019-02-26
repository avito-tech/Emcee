import DateProvider
import DateProviderTestHelpers
import Foundation
import WorkerAlivenessTracker
import BucketQueue

public final class BucketQueueFixtures {
    public static func bucketQueue(
        checkAgainTimeInterval: TimeInterval = 30,
        dateProvider: DateProvider = DateProviderFixture(),
        testHistoryTracker: TestHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker(),
        workerAlivenessProvider: WorkerAlivenessProvider)
        -> BucketQueue
    {
        return BucketQueueFactory(
            checkAgainTimeInterval: checkAgainTimeInterval,
            dateProvider: dateProvider,
            testHistoryTracker: testHistoryTracker,
            workerAlivenessProvider: workerAlivenessProvider)
            .createBucketQueue()
    }
}
