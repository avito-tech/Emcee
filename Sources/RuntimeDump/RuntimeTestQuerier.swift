import Models

public protocol RuntimeTestQuerier {
    func queryRuntime(configuration: RuntimeDumpConfiguration) throws -> RuntimeQueryResult
}
