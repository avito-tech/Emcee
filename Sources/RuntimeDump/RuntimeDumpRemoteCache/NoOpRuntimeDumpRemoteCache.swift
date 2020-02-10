import Models

class NoOpRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    func results(xcTestBundleLocation: TestBundleLocation) -> TestsInRuntimeDump? {
        return nil
    }

    func store(tests: TestsInRuntimeDump, xcTestBundleLocation: TestBundleLocation) {

    }
}
