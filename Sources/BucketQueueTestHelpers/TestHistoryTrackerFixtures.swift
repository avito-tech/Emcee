import BucketQueue

public final class TestHistoryTrackerFixtures {
    public static func testHistoryTracker(numberOfRetries: UInt = 0) -> TestHistoryTracker {
        return TestHistoryTrackerImpl(
            numberOfRetries: numberOfRetries,
            testHistoryStorage: TestHistoryStorageImpl()
        )
    }
}
