import Foundation
import Models

public struct TestEntriesValidatorConfiguration {
    public let simulatorControlTool: SimulatorControlTool
    public let testArgFileEntries: [TestArgFile.Entry]
    public let testRunnerTool: TestRunnerTool

    public init(
        simulatorControlTool: SimulatorControlTool,
        testArgFileEntries: [TestArgFile.Entry],
        testRunnerTool: TestRunnerTool
    ) {
        self.simulatorControlTool = simulatorControlTool
        self.testArgFileEntries = testArgFileEntries
        self.testRunnerTool = testRunnerTool
    }
}
