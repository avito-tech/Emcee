import Foundation
import Models

public struct TestEntriesValidatorConfiguration {
    public let fbxctest: FbxctestLocation
    public let fbsimctl: FbsimctlLocation?
    public let testDestination: TestDestination
    public let testEntries: [TestArgFile.Entry]

    public init(
        fbxctest: FbxctestLocation,
        fbsimctl: FbsimctlLocation?,
        testDestination: TestDestination,
        testEntries: [TestArgFile.Entry]
    ) {
        self.fbxctest = fbxctest
        self.fbsimctl = fbsimctl
        self.testDestination = testDestination
        self.testEntries = testEntries
    }
}
