import Models

public final class TestHistoryTrackerAcceptResult {
    public let bucketsToReenqueue: [Bucket]
    public let testingResult: TestingResult
    
    public init(
        bucketsToReenqueue: [Bucket],
        testingResult: TestingResult)
    {
        self.bucketsToReenqueue = bucketsToReenqueue
        self.testingResult = testingResult
    }
}
