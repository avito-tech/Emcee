@testable import RuntimeDump
import Models

final class RuntimeTestQuerierMock: RuntimeTestQuerier {
    var configuration: RuntimeDumpConfiguration?
    func queryRuntime(configuration: RuntimeDumpConfiguration) throws -> RuntimeQueryResult {
        self.configuration = configuration
        
        return RuntimeQueryResult(
            unavailableTestsToRun: [],
            availableRuntimeTests: []
        )
    }
}
