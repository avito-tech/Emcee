@testable import TestDiscovery
import Models

final class TestDiscoveryResultFixtures {
    static func queryResult() -> TestDiscoveryResult {
        return TestDiscoveryResult(
            discoveredTests: DiscoveredTests(tests: [DiscoveredTestEntryFixtures.entry()]),
            unavailableTestsToRun: [TestToRun.testName(TestName(className: "Class", methodName: "unavailableTest"))]
        )
    }
}
