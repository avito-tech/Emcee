import BucketQueue
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import Foundation

public final class TestHistoryTrackerFixtures {
    public static func testHistoryTracker(uniqueIdentifierGenerator: UniqueIdentifierGenerator) -> TestHistoryTracker {
        return TestHistoryTrackerImpl(
            testHistoryStorage: TestHistoryStorageImpl(),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
}
