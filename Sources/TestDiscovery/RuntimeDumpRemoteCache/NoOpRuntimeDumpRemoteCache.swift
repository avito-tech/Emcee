import BuildArtifacts

public final class NoOpRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    public init() {}
    
    public func results(xcTestBundleLocation: TestBundleLocation) -> DiscoveredTests? {
        return nil
    }

    public func store(tests: DiscoveredTests, xcTestBundleLocation: TestBundleLocation) {

    }
}
