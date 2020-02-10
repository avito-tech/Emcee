@testable import RuntimeDump
import Models

final class RuntimeQueryResultFixtures {
    static func queryResult() -> RuntimeQueryResult {
        return RuntimeQueryResult(
            unavailableTestsToRun: [TestToRun.testName(TestName(className: "Class", methodName: "unavailableTest"))],
            testsInRuntimeDump: TestsInRuntimeDump(tests: [RuntimeTestEntryFixtures.entry()])
        )
    }
}
