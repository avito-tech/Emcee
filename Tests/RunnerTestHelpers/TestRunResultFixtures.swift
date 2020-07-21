import Foundation
import RunnerModels

public final class TestRunResultFixtures {
    public static func testRunResult(succeeded: Bool = true, timestamp: TimeInterval = 0) -> TestRunResult {
        return TestRunResult(
            succeeded: succeeded,
            exceptions: [],
            duration: 0,
            startTime: timestamp,
            hostName: "",
            simulatorId: ""
        )
    }
}
