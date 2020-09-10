import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import WorkerCapabilitiesModels

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
    public let workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    public let persistentMetricsJobId: String

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
        testType: TestType,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>,
        persistentMetricsJobId: String
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
        self.workerCapabilityRequirements = workerCapabilityRequirements
        self.persistentMetricsJobId = persistentMetricsJobId
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testType) \(testDestination) \(buildArtifacts) \(pluginLocations) \(simulatorSettings) \(testExecutionBehavior) \(testTimeoutConfiguration) \(simulatorControlTool) \(simulatorOperationTimeouts) \(testRunnerTool) \(developerDir) \(workerCapabilityRequirements) \(persistentMetricsJobId)>"
    }
}
