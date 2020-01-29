import Models

class NoOpRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    func results(xcTestBundleLocation: TestBundleLocation) -> RuntimeQueryResult? {
        return nil
    }

    func store(result: RuntimeQueryResult, xcTestBundleLocation: TestBundleLocation) {

    }
}
