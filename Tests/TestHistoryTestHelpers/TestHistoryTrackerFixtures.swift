import BucketQueue
import Foundation
import TestHistoryTracker
import TestHistoryStorage
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers

public final class TestHistoryTrackerFixtures {
    public static func testHistoryTracker(uniqueIdentifierGenerator: UniqueIdentifierGenerator) -> TestHistoryTracker {
        return TestHistoryTrackerImpl(
            testHistoryStorage: TestHistoryStorageImpl(),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
}
