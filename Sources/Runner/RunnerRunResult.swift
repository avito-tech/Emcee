import CommonTestModels
import Foundation

public final class RunnerRunResult {
    public let runnerWasteCollector: RunnerWasteCollector
    public let testEntryResults: [TestEntryResult]

    public init(
        runnerWasteCollector: RunnerWasteCollector,
        testEntryResults: [TestEntryResult]
    ) {
        self.runnerWasteCollector = runnerWasteCollector
        self.testEntryResults = testEntryResults
    }
}
