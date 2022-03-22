import CommonTestModels
import Foundation

public final class RunnerRunResult {
    public let runnerWasteCollector: RunnerWasteCollector
    public let testEntryResults: [TestEntryResult]
    public let xcresultData: [Data]

    public init(
        runnerWasteCollector: RunnerWasteCollector,
        testEntryResults: [TestEntryResult],
        xcresultData: [Data]
    ) {
        self.runnerWasteCollector = runnerWasteCollector
        self.testEntryResults = testEntryResults
        self.xcresultData = xcresultData
    }
}
