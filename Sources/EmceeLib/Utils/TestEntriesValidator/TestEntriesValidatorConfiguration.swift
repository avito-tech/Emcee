import Foundation
import Models

public struct TestEntriesValidatorConfiguration {
    public let fbxctest: FbxctestLocation
    public let simulatorControlTool: SimulatorControlTool?
    public let testDestination: TestDestination
    public let testEntries: [TestArgFile.Entry]

    public init(
        fbxctest: FbxctestLocation,
        simulatorControlTool: SimulatorControlTool?,
        testDestination: TestDestination,
        testEntries: [TestArgFile.Entry]
    ) {
        self.fbxctest = fbxctest
        self.simulatorControlTool = simulatorControlTool
        self.testDestination = testDestination
        self.testEntries = testEntries
    }
}
