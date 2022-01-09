import Foundation
import EmceeLogging
import PathLib
import ProcessController
import RunnerModels

public final class RunnerRunResult {
    public let entriesToRun: [TestEntry]
    public let runnerWasteCollector: RunnerWasteCollector
    public let testEntryResults: [TestEntryResult]

    public init(
        entriesToRun: [TestEntry],
        runnerWasteCollector: RunnerWasteCollector,
        testEntryResults: [TestEntryResult]
    ) {
        self.entriesToRun = entriesToRun
        self.runnerWasteCollector = runnerWasteCollector
        self.testEntryResults = testEntryResults
    }
}
