import BucketQueue
import DateProvider
import DateProviderTestHelpers
import Foundation
import TestHistoryTestHelpers
import TestHistoryTracker
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import WorkerAlivenessProvider
import WorkerCapabilities

public final class BucketQueueFixtures {
    public static let fixedGeneratorValue = UUID().uuidString

    public static func bucketQueue(
        checkAgainTimeInterval: TimeInterval = 30,
        dateProvider: DateProvider = DateProviderFixture(),
        testHistoryTracker: TestHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(value: fixedGeneratorValue)
        ),
        uniqueIdentifierGenerator: UniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
            value: fixedGeneratorValue
        ),
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    ) -> BucketQueue {
        return BucketQueueFactoryImpl(
            checkAgainTimeInterval: checkAgainTimeInterval,
            dateProvider: dateProvider,
            testHistoryTracker: testHistoryTracker,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
            .createBucketQueue()
    }
}
