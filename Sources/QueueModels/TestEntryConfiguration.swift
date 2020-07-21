import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import RunnerModels
import SimulatorPoolModels

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let simulatorControlTool: SimulatorControlTool
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntry: TestEntry
    public let testExecutionBehavior: TestExecutionBehavior
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType

    public init(
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        simulatorControlTool: SimulatorControlTool,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntry: TestEntry,
        testExecutionBehavior: TestExecutionBehavior,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.simulatorControlTool = simulatorControlTool
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntry = testEntry
        self.testExecutionBehavior = testExecutionBehavior
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testType) \(testDestination) \(buildArtifacts) \(pluginLocations) \(simulatorSettings) \(testExecutionBehavior) \(testTimeoutConfiguration) \(simulatorControlTool) \(simulatorOperationTimeouts) \(testRunnerTool) \(developerDir)>"
    }
}
