@testable import RuntimeDump
import Models

final class RuntimeQueryResultFixtures {
    static func queryResult() -> RuntimeQueryResult {
        return RuntimeQueryResult(
            unavailableTestsToRun: [TestToRun.testName(TestName(className: "Class", methodName: "unavailableTest"))],
            availableRuntimeTests: [RuntimeTestEntry(className: "Class", path: "", testMethods: ["availableTest"], caseId: nil, tags: [])]
        )
    }
}
