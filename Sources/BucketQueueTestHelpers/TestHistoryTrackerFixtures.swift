import BucketQueue

public final class TestHistoryTrackerFixtures {
    public static func testHistoryTracker() -> TestHistoryTracker {
        return TestHistoryTrackerImpl(
            testHistoryStorage: TestHistoryStorageImpl()
        )
    }
}
