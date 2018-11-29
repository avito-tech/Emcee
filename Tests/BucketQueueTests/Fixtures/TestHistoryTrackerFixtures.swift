import BucketQueue

final class TestHistoryTrackerFixtures {
    static func testHistoryTracker(numberOfRetries: UInt = 0) -> TestHistoryTracker {
        return TestHistoryTrackerImpl(
            numberOfRetries: numberOfRetries,
            testHistoryStorage: TestHistoryStorageImpl()
        )
    }
}
