import Foundation
import RunnerModels

extension TestStoppedEvent {
    func byMerging(
        testExceptions: [TestException],
        logs: [TestLogEntry]
    ) -> TestStoppedEvent {
        var event = self
        
        for exception in testExceptions {
            if exception.relatedTestName == testName || exception.relatedTestName == nil {
                event.add(testException: exception)
            }
        }
        
        logs.forEach {
            event.add(logEntry: $0)
        }
        
        return event
    }
}
