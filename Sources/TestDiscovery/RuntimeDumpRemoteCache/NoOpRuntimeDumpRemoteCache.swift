import BuildArtifacts

class NoOpRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    func results(xcTestBundleLocation: TestBundleLocation) -> DiscoveredTests? {
        return nil
    }

    func store(tests: DiscoveredTests, xcTestBundleLocation: TestBundleLocation) {

    }
}
