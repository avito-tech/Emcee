import DateProvider
import Foundation
import ResultStreamModels
import RunnerModels

extension RSTestFinished {
    func testStoppedEvent(
        dateProvider: DateProvider
    ) throws -> TestStoppedEvent {
        let testDuration = structuredPayload.test.duration?.doubleValue ?? 0.0
        return TestStoppedEvent(
            testName: try structuredPayload.test.testName(),
            result: structuredPayload.test.testStatus == "Success" ? .success : .failure,
            testDuration: testDuration,
            testExceptions: [],
            logs: [],
            testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-testDuration).timeIntervalSince1970
        )
    }
}
