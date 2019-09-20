import Foundation
import Models

public struct TestEntriesValidatorConfiguration {
    public let simulatorControlTool: SimulatorControlTool?
    public let testDestination: TestDestination
    public let testArgFileEntries: [TestArgFile.Entry]
    public let testRunnerTool: TestRunnerTool

    public init(
        simulatorControlTool: SimulatorControlTool?,
        testDestination: TestDestination,
        testArgFileEntries: [TestArgFile.Entry],
        testRunnerTool: TestRunnerTool
    ) {
        self.simulatorControlTool = simulatorControlTool
        self.testDestination = testDestination
        self.testArgFileEntries = testArgFileEntries
        self.testRunnerTool = testRunnerTool
    }
}
