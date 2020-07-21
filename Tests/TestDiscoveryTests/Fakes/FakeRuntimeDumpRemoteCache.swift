import BuildArtifacts
import TestDiscovery

class FakeRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    var testsToReturn: DiscoveredTests?
    var resultsXcTestBundleLocation: TestBundleLocation?
    func results(xcTestBundleLocation: TestBundleLocation) throws -> DiscoveredTests? {
        guard resultsXcTestBundleLocation == xcTestBundleLocation else {
            return nil
        }

        return testsToReturn
    }

    var storedTests: DiscoveredTests?
    var storedXcTestBundleLocation: TestBundleLocation?
    func store(tests: DiscoveredTests, xcTestBundleLocation: TestBundleLocation) {
        self.storedTests  = tests
        self.storedXcTestBundleLocation = xcTestBundleLocation
    }
}
