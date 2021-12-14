import QueueModels
import RunnerModels

public final class TestHistoryTrackerAcceptResult {
    /// Indicates that these tests may need to be rescheduled into the queue for retry.
    public let testEntriesToReenqueue: [TestEntry]
    
    /// Testing result suitable for usage. This result may miss test runs that were negative, but eventually have been corrected because of retries.
    public let testingResult: TestingResult
    
    public init(
        testEntriesToReenqueue: [TestEntry],
        testingResult: TestingResult
    ) {
        self.testEntriesToReenqueue = testEntriesToReenqueue
        self.testingResult = testingResult
    }
}
