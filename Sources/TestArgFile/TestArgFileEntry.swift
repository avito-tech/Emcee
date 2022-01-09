import BuildArtifacts
import DeveloperDirModels
import Foundation
import PluginSupport
import QueueModels
import RunnerModels
import ScheduleStrategy
import SimulatorPoolModels
import WorkerCapabilitiesModels

public struct TestArgFileEntry: Codable, Equatable {
    public private(set) var buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let userInsertedLibraries: [String]
    public let numberOfRetries: UInt
    public let testRetryMode: TestRetryMode
    public let logCapturingMode: LogCapturingMode
    public let runnerWasteCleanupPolicy: RunnerWasteCleanupPolicy
    public let pluginLocations: Set<PluginLocation>
    public let scheduleStrategy: ScheduleStrategy
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testsToRun: [TestToRun]
    public let workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    
    public init(
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        environment: [String: String],
        userInsertedLibraries: [String],
        numberOfRetries: UInt,
        testRetryMode: TestRetryMode,
        logCapturingMode: LogCapturingMode,
        runnerWasteCleanupPolicy: RunnerWasteCleanupPolicy,
        pluginLocations: Set<PluginLocation>,
        scheduleStrategy: ScheduleStrategy,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testsToRun: [TestToRun],
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.environment = environment
        self.userInsertedLibraries = userInsertedLibraries
        self.numberOfRetries = numberOfRetries
        self.testRetryMode = testRetryMode
        self.logCapturingMode = logCapturingMode
        self.runnerWasteCleanupPolicy = runnerWasteCleanupPolicy
        self.pluginLocations = pluginLocations
        self.scheduleStrategy = scheduleStrategy
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testsToRun = testsToRun
        self.workerCapabilityRequirements = workerCapabilityRequirements
    }
    
    public func with(buildArtifacts: BuildArtifacts) -> Self {
        var result = self
        result.buildArtifacts = buildArtifacts
        return result
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let buildArtifacts = try container.decode(BuildArtifacts.self, forKey: .buildArtifacts)
        let testDestination = try container.decode(TestDestination.self, forKey: .testDestination)
        let testsToRun = try container.decode([TestToRun].self, forKey: .testsToRun)
        
        let developerDir = try container.decodeIfPresent(DeveloperDir.self, forKey: .developerDir) ??
            TestArgFileDefaultValues.developerDir
        let environment = try container.decodeIfPresent([String: String].self, forKey: .environment) ??
            TestArgFileDefaultValues.environment
        let userInsertedLibraries = try container.decodeIfPresent([String].self, forKey: .userInsertedLibraries) ??
            TestArgFileDefaultValues.userInsertedLibraries
        let numberOfRetries = try container.decodeIfPresent(UInt.self, forKey: .numberOfRetries) ??
            TestArgFileDefaultValues.numberOfRetries
        let testRetryMode = try container.decodeIfPresent(TestRetryMode.self, forKey: .testRetryMode) ??
            TestArgFileDefaultValues.testRetryMode
        let logCapturingMode = try container.decodeIfPresent(LogCapturingMode.self, forKey: .logCapturingMode) ??
            TestArgFileDefaultValues.logCapturingMode
        let pluginLocations = try container.decodeIfPresent(Set<PluginLocation>.self, forKey: .pluginLocations) ??
            TestArgFileDefaultValues.pluginLocations
        let scheduleStrategy = try container.decodeIfPresent(ScheduleStrategy.self, forKey: .scheduleStrategy) ??
            TestArgFileDefaultValues.scheduleStrategy
        let simulatorOperationTimeouts = try container.decodeIfPresent(SimulatorOperationTimeouts.self, forKey: .simulatorOperationTimeouts) ??
            TestArgFileDefaultValues.simulatorOperationTimeouts
        let simulatorSettings = try container.decodeIfPresent(SimulatorSettings.self, forKey: .simulatorSettings) ??
            TestArgFileDefaultValues.simulatorSettings
        let runnerWasteCleanupPolicy = try container.decodeIfPresent(RunnerWasteCleanupPolicy.self, forKey: .runnerWasteCleanupPolicy) ??
            TestArgFileDefaultValues.runnerWasteCleanupPolicy
        
        let testTimeoutConfiguration = try container.decodeIfPresent(TestTimeoutConfiguration.self, forKey: .testTimeoutConfiguration) ??
            TestArgFileDefaultValues.testTimeoutConfiguration
        let workerCapabilityRequirements = try container.decodeIfPresent(Set<WorkerCapabilityRequirement>.self, forKey: .workerCapabilityRequirements) ??
            TestArgFileDefaultValues.workerCapabilityRequirements

        self.init(
            buildArtifacts: buildArtifacts,
            developerDir: developerDir,
            environment: environment,
            userInsertedLibraries: userInsertedLibraries,
            numberOfRetries: numberOfRetries,
            testRetryMode: testRetryMode,
            logCapturingMode: logCapturingMode,
            runnerWasteCleanupPolicy: runnerWasteCleanupPolicy,
            pluginLocations: pluginLocations,
            scheduleStrategy: scheduleStrategy,
            simulatorOperationTimeouts: simulatorOperationTimeouts,
            simulatorSettings: simulatorSettings,
            testDestination: testDestination,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testsToRun: testsToRun,
            workerCapabilityRequirements: workerCapabilityRequirements
        )
    }
}
