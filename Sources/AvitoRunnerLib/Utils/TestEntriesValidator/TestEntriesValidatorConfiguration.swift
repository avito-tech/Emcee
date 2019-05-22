import Foundation
import Models

public struct TestEntriesValidatorConfiguration {
    public let fbxctest: FbxctestLocation
    public let xcTestBundle: TestBundleLocation
    public let applicationTestSupport: RuntimeDumpApplicationTestSupport?
    public let testDestination: TestDestination
    public let testEntries: [TestArgFile.Entry]
    public var supportsApplicationTests: Bool {
        return applicationTestSupport != nil
    }

    public init(
        fbxctest: FbxctestLocation,
        xcTestBundle: TestBundleLocation,
        applicationTestSupport: RuntimeDumpApplicationTestSupport?,
        testDestination: TestDestination,
        testEntries: [TestArgFile.Entry]
    ) {
        self.fbxctest = fbxctest
        self.xcTestBundle = xcTestBundle
        self.applicationTestSupport = applicationTestSupport
        self.testDestination = testDestination
        self.testEntries = testEntries
    }
}
