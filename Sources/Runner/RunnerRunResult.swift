import Foundation
import Logging
import PathLib
import ProcessController
import RunnerModels

public final class RunnerRunResult {
    public let entriesToRun: [TestEntry]
    public let testEntryResults: [TestEntryResult]

    public init(
        entriesToRun: [TestEntry],
        testEntryResults: [TestEntryResult]
    ) {
        self.entriesToRun = entriesToRun
        self.testEntryResults = testEntryResults
    }
}
