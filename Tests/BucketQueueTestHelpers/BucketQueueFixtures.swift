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
        dateProvider: DateProvider = DateProviderFixture(),
        testHistoryTracker: TestHistoryTracker = TestHistoryTrackerFixtures.testHistoryTracker(
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(value: fixedGeneratorValue)
        ),
        uniqueIdentifierGenerator: UniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(
            value: fixedGeneratorValue
        ),
        workerAlivenessProvider: WorkerAlivenessProvider,
        workerCapabilitiesStorage: WorkerCapabilitiesStorage = WorkerCapabilitiesStorageImpl()
    ) -> BucketQueueImpl {
        return BucketQueueFactoryImpl(
            dateProvider: dateProvider,
            logger: .noOp,
            testHistoryTracker: testHistoryTracker,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessProvider: workerAlivenessProvider,
            workerCapabilitiesStorage: workerCapabilitiesStorage
        )
            .createBucketQueue()
    }
}
