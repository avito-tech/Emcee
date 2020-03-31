import BuildArtifacts

public protocol RuntimeDumpRemoteCache {
    func results(xcTestBundleLocation: TestBundleLocation) throws -> DiscoveredTests?
    func store(tests: DiscoveredTests, xcTestBundleLocation: TestBundleLocation) throws
}
