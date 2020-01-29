import RuntimeDump
import Models

class FakeRuntimeDumpRemoteCache: RuntimeDumpRemoteCache {

    var resultToReturn: RuntimeQueryResult?
    var resultsXcTestBundleLocation: TestBundleLocation?
    func results(xcTestBundleLocation: TestBundleLocation) -> RuntimeQueryResult? {
        guard resultsXcTestBundleLocation == xcTestBundleLocation else {
            return nil
        }

        return resultToReturn
    }

    var storedResult: RuntimeQueryResult?
    var storedXcTestBundleLocation: TestBundleLocation?
    func store(result: RuntimeQueryResult, xcTestBundleLocation: TestBundleLocation) {
        self.storedResult = result
        self.storedXcTestBundleLocation = xcTestBundleLocation
    }
}
