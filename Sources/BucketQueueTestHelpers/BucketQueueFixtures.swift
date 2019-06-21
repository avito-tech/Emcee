import BucketQueue
import DateProvider
import DateProviderTestHelpers
import Foundation
import UniqueIdentifierGenerator
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessTracker

public final class BucketQueueFixtures {
    public static let fixedGeneratorValue = UUID().uuidString

    public static func bucketQueue(
        checkAgainTimeInterval: TimeInterval = 30,
        dateProvider: DateProvider = DateProviderFixture(),
        testHistoryTracker: TestHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker(
            generatorValue: fixedGeneratorValue
        ),
        uniqueIdentifierGenerator: UniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
            value: fixedGeneratorValue
        ),
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
