import BuildArtifacts
import DeveloperDirModels
import Foundation
import MetricsExtensions
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import WorkerCapabilitiesModels

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let buildArtifacts: IosBuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<PluginLocation>
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testEntry: TestEntry
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let workerCapabilityRequirements: Set<WorkerCapabilityRequirement>

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        buildArtifacts: IosBuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<PluginLocation>,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testEntry: TestEntry,
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    ) {
        self.analyticsConfiguration = analyticsConfiguration
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.pluginLocations = pluginLocations
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testEntry = testEntry
        self.testExecutionBehavior = testExecutionBehavior
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.workerCapabilityRequirements = workerCapabilityRequirements
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testDestination) \(buildArtifacts) \(pluginLocations) \(simulatorSettings) \(testExecutionBehavior) \(testTimeoutConfiguration) \(simulatorOperationTimeouts) \(developerDir) \(workerCapabilityRequirements) \(analyticsConfiguration)>"
    }
}
