import Models

public protocol RuntimeDumpRemoteCache {
    func results(xcTestBundleLocation: TestBundleLocation) throws -> RuntimeQueryResult?
    func store(result: RuntimeQueryResult, xcTestBundleLocation: TestBundleLocation)
}
