import RuntimeDump
import Models

class FakeRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {
    var testsToReturn: TestsInRuntimeDump?
    var resultsXcTestBundleLocation: TestBundleLocation?
    func results(xcTestBundleLocation: TestBundleLocation) throws -> TestsInRuntimeDump? {
        guard resultsXcTestBundleLocation == xcTestBundleLocation else {
            return nil
        }

        return testsToReturn
    }

    var storedTests: TestsInRuntimeDump?
    var storedXcTestBundleLocation: TestBundleLocation?
    func store(tests: TestsInRuntimeDump, xcTestBundleLocation: TestBundleLocation) {
        self.storedTests  = tests
        self.storedXcTestBundleLocation = xcTestBundleLocation
    }
}
