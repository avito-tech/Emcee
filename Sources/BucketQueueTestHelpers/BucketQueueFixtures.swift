import BucketQueue
import DateProvider
import DateProviderTestHelpers
import Foundation
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessTracker

public final class BucketQueueFixtures {
    public static func bucketQueue(
        checkAgainTimeInterval: TimeInterval = 30,
        dateProvider: DateProvider = DateProviderFixture(),
        testHistoryTracker: TestHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker(),
        uniqueIdentifierGenerator: UniqueIdentifierGenerator = FixedUniqueIdentifierGenerator(),
        workerAlivenessProvider: WorkerAlivenessProvider
    ) -> BucketQueue {
        return BucketQueueFactory(
            checkAgainTimeInterval: checkAgainTimeInterval,
            dateProvider: dateProvider,
            testHistoryTracker: testHistoryTracker,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider)
            .createBucketQueue()
    }
}
