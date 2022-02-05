import BuildArtifacts
import DeveloperDirModels
import Foundation
import MetricsExtensions
import PluginSupport
import RunnerModels
import SimulatorPoolModels
import TestDestination
import WorkerCapabilitiesModels

public struct TestEntryConfiguration: Codable, CustomStringConvertible, Hashable {
    public let analyticsConfiguration: AnalyticsConfiguration
    public let buildArtifacts: AppleBuildArtifacts
    public let developerDir: DeveloperDir
    public let pluginLocations: Set<AppleTestPluginLocation>
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: AppleTestDestination
    public let testEntry: TestEntry
    public let testExecutionBehavior: TestExecutionBehavior
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testAttachmentLifetime: TestAttachmentLifetime
    public let workerCapabilityRequirements: Set<WorkerCapabilityRequirement>

    public init(
        analyticsConfiguration: AnalyticsConfiguration,
        buildArtifacts: AppleBuildArtifacts,
        developerDir: DeveloperDir,
        pluginLocations: Set<AppleTestPluginLocation>,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: AppleTestDestination,
        testEntry: TestEntry,
        testExecutionBehavior: TestExecutionBehavior,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testAttachmentLifetime: TestAttachmentLifetime,
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
        self.testAttachmentLifetime = testAttachmentLifetime
        self.workerCapabilityRequirements = workerCapabilityRequirements
    }
    
    public var description: String {
        return "<\(type(of: self)): \(testEntry) \(testDestination) \(buildArtifacts) \(pluginLocations) \(simulatorSettings) \(testExecutionBehavior) \(testTimeoutConfiguration) \(simulatorOperationTimeouts) \(developerDir) \(workerCapabilityRequirements) \(analyticsConfiguration) \(testAttachmentLifetime)>"
    }
}
