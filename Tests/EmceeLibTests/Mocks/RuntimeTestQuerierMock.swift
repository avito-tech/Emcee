@testable import RuntimeDump
import Models

final class RuntimeTestQuerierMock: RuntimeTestQuerier {
    var numberOfCalls = 0
    var configuration: RuntimeDumpConfiguration?
    func queryRuntime(configuration: RuntimeDumpConfiguration) throws -> RuntimeQueryResult {
        numberOfCalls += 1
        self.configuration = configuration
        
        return RuntimeQueryResult(
            unavailableTestsToRun: [],
            testsInRuntimeDump: TestsInRuntimeDump(tests: [])
        )
    }
}
