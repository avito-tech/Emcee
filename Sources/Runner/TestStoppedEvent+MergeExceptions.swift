import Foundation
import RunnerModels

extension TestStoppedEvent {
    func byMergingTestExceptions(
        testExceptions: [TestException]
    ) -> TestStoppedEvent {
        return TestStoppedEvent(
            testName: testName,
            result: result,
            testDuration: testDuration,
            testExceptions: testExceptions + self.testExceptions,
            testStartTimestamp: testStartTimestamp
        )
    }
}
