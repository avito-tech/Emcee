import Foundation
import RunnerModels

extension TestStoppedEvent {
    func byMerging(
        testExceptions: [TestException],
        logs: [TestLogEntry]
    ) -> TestStoppedEvent {
        return TestStoppedEvent(
            testName: testName,
            result: result,
            testDuration: testDuration,
            testExceptions: testExceptions + self.testExceptions,
            logs: logs + self.logs,
            testStartTimestamp: testStartTimestamp
        )
    }
}
