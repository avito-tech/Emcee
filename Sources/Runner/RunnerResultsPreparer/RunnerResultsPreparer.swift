import CommonTestModels
import Foundation

public protocol RunnerResultsPreparer {
    func prepareResults(
        collectedTestStoppedEvents: [TestStoppedEvent],
        collectedTestExceptions: [TestException],
        collectedLogs: [TestLogEntry],
        requestedEntriesToRun: [TestEntry],
        udid: UDID
    ) -> [TestEntryResult]
}
