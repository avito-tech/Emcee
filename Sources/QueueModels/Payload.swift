import BuildArtifacts
import DeveloperDirModels
import RunnerModels
import SimulatorPoolModels
import Foundation

public struct Payload: Codable, Hashable, CustomStringConvertible {
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntries: [TestEntry]
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration

    public init(
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntries: [TestEntry],
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntries = testEntries
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
    }

    public var description: String {
        "run \(testEntries.count) tests"
    }

    public func with(testEntries newTestEntries: [TestEntry]) -> Payload {
        Payload(
            buildArtifacts: buildArtifacts,
            developerDir: developerDir,
            simulatorOperationTimeouts: simulatorOperationTimeouts,
            simulatorSettings: simulatorSettings,
            testDestination: testDestination,
            testEntries: newTestEntries,
            testExecutionBehavior: testExecutionBehavior,
            testTimeoutConfiguration: testTimeoutConfiguration
        )
    }
}
