import CommonTestModels
import EmceeTypes
import Foundation

public final class TestRunResultFixtures {
    public static func testRunResult(
        succeeded: Bool = true,
        timestamp: DateSince1970ReferenceDate = DateSince1970ReferenceDate(timeIntervalSince1970: 0)
    ) -> TestRunResult {
        return TestRunResult(
            succeeded: succeeded,
            exceptions: [],
            logs: [],
            duration: 0,
            startTime: timestamp,
            hostName: "",
            udid: ""
        )
    }
}
