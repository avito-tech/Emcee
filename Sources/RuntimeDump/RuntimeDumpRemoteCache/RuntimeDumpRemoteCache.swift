import Models

public protocol RuntimeDumpRemoteCache {
    func results(xcTestBundleLocation: TestBundleLocation) throws -> TestsInRuntimeDump?
    func store(tests: TestsInRuntimeDump, xcTestBundleLocation: TestBundleLocation)
}
