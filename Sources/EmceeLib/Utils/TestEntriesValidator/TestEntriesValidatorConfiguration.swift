import Foundation
import Models

public struct TestEntriesValidatorConfiguration {
    public let simulatorControlTool: SimulatorControlTool?
    public let testDestination: TestDestination
    public let testEntries: [TestArgFile.Entry]
    public let testRunnerTool: TestRunnerTool

    public init(
        simulatorControlTool: SimulatorControlTool?,
        testDestination: TestDestination,
        testEntries: [TestArgFile.Entry],
        testRunnerTool: TestRunnerTool
    ) {
        self.simulatorControlTool = simulatorControlTool
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.testRunnerTool = testRunnerTool
    }
}
