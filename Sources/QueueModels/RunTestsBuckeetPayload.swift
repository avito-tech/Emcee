import BuildArtifacts
import DeveloperDirModels
import RunnerModels
import SimulatorPoolModels
import Foundation

public struct RunTestsBucketPayload: Codable, Hashable, CustomStringConvertible {
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let simulatorControlTool: SimulatorControlTool
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType

    public init(
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        simulatorControlTool: SimulatorControlTool,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.simulatorControlTool = simulatorControlTool
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
    }

    public var description: String {
        "run \(testEntries.count) tests"
    }

    public func with(testEntries newTestEntries: [TestEntry]) -> RunTestsBucketPayload {
        RunTestsBucketPayload(
            buildArtifacts: buildArtifacts,
            developerDir: developerDir,
            simulatorControlTool: simulatorControlTool,
            simulatorOperationTimeouts: simulatorOperationTimeouts,
            simulatorSettings: simulatorSettings,
            testDestination: testDestination,
            testEntries: newTestEntries,
            testExecutionBehavior: testExecutionBehavior,
            testRunnerTool: testRunnerTool,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testType: testType
        )
    }
}
