import BuildArtifacts
import Foundation

public final class XcTestBundleFixture {
    public var location: TestBundleLocation
    public var testDiscoveryMode: XcTestBundleTestDiscoveryMode
    
    public init(
        location: TestBundleLocation = TestBundleLocation(.localFilePath("/bundle.xctest")),
        testDiscoveryMode: XcTestBundleTestDiscoveryMode = .parseFunctionSymbols
    ) {
        self.location = location
        self.testDiscoveryMode = testDiscoveryMode
    }
    
    public func with(location: TestBundleLocation) -> Self {
        self.location = location
        return self
    }
    
    public func with(testDiscoveryMode: XcTestBundleTestDiscoveryMode) -> Self {
        self.testDiscoveryMode = testDiscoveryMode
        return self
    }
    
    public func with(localPath: String) -> Self {
        with(location: TestBundleLocation(.localFilePath(localPath)))
    }
    
    public func with(url: URL, headers: [String : String]? = nil) -> Self {
        with(location: TestBundleLocation(.remoteUrl(url, headers)))
    }
    
    public func xcTestBundle() -> XcTestBundle {
        XcTestBundle(
            location: location,
            testDiscoveryMode: testDiscoveryMode
        )
    }
}
