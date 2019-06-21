import BucketQueue
import UniqueIdentifierGeneratorTestHelpers
import Foundation

public final class
TestHistoryTrackerFixtures {
    public static func testHistoryTracker(generatorValue: String = UUID().uuidString) -> TestHistoryTracker {
        return TestHistoryTrackerImpl(
            testHistoryStorage: TestHistoryStorageImpl(),
            uniqueIdentifierGenerator: FixedValueUniqueIdentifierGenerator(value: generatorValue)
        )
    }
}
