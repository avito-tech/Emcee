import Foundation
import RunnerModels
import SimulatorPoolModels

public protocol RunnerResultsPreparer {
    func prepareResults(
        collectedTestStoppedEvents: [TestStoppedEvent],
        collectedTestExceptions: [TestException],
        collectedLogs: [TestLogEntry],
        requestedEntriesToRun: [TestEntry],
        udid: UDID
    ) -> [TestEntryResult]
}
