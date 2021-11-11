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
    public let buildArtifacts: BuildArtifacts
    public let developerDir: DeveloperDir
    public let environment: [String: String]
    public let numberOfRetries: UInt
    public let pluginLocations: Set<PluginLocation>
    public let scheduleStrategy: ScheduleStrategy
    public let simulatorControlTool: SimulatorControlTool
    public let simulatorOperationTimeouts: SimulatorOperationTimeouts
    public let simulatorSettings: SimulatorSettings
    public let testDestination: TestDestination
    public let testRunnerTool: TestRunnerTool
    public let testTimeoutConfiguration: TestTimeoutConfiguration
    public let testType: TestType
    public let testsToRun: [TestToRun]
    public let workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    
    public init(
        buildArtifacts: BuildArtifacts,
        developerDir: DeveloperDir,
        environment: [String: String],
        numberOfRetries: UInt,
        pluginLocations: Set<PluginLocation>,
        scheduleStrategy: ScheduleStrategy,
        simulatorControlTool: SimulatorControlTool,
        simulatorOperationTimeouts: SimulatorOperationTimeouts,
        simulatorSettings: SimulatorSettings,
        testDestination: TestDestination,
        testRunnerTool: TestRunnerTool,
        testTimeoutConfiguration: TestTimeoutConfiguration,
        testType: TestType,
        testsToRun: [TestToRun],
        workerCapabilityRequirements: Set<WorkerCapabilityRequirement>
    ) {
        self.buildArtifacts = buildArtifacts
        self.developerDir = developerDir
        self.environment = environment
        self.numberOfRetries = numberOfRetries
        self.pluginLocations = pluginLocations
        self.scheduleStrategy = scheduleStrategy
        self.simulatorControlTool = simulatorControlTool
        self.simulatorOperationTimeouts = simulatorOperationTimeouts
        self.simulatorSettings = simulatorSettings
        self.testDestination = testDestination
        self.testRunnerTool = testRunnerTool
        self.testTimeoutConfiguration = testTimeoutConfiguration
        self.testType = testType
        self.testsToRun = testsToRun
        self.workerCapabilityRequirements = workerCapabilityRequirements
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        let buildArtifacts = try container.decode(BuildArtifacts.self, forKey: .buildArtifacts)
        let testDestination = try container.decode(TestDestination.self, forKey: .testDestination)
        let testType = try container.decode(TestType.self, forKey: .testType)
        let testsToRun = try container.decode([TestToRun].self, forKey: .testsToRun)
        
        let developerDir = try container.decodeIfPresent(DeveloperDir.self, forKey: .developerDir) ??
            TestArgFileDefaultValues.developerDir
        let environment = try container.decodeIfPresent([String: String].self, forKey: .environment) ??
            TestArgFileDefaultValues.environment
        let numberOfRetries = try container.decodeIfPresent(UInt.self, forKey: .numberOfRetries) ??
            TestArgFileDefaultValues.numberOfRetries
        let pluginLocations = try container.decodeIfPresent(Set<PluginLocation>.self, forKey: .pluginLocations) ??
            TestArgFileDefaultValues.pluginLocations
        let scheduleStrategy = try container.decodeIfPresent(ScheduleStrategy.self, forKey: .scheduleStrategy) ??
            TestArgFileDefaultValues.scheduleStrategy
        let simulatorControlTool = try container.decodeIfPresent(SimulatorControlTool.self, forKey: .simulatorControlTool) ??
            TestArgFileDefaultValues.simulatorControlTool
        let simulatorOperationTimeouts = try container.decodeIfPresent(SimulatorOperationTimeouts.self, forKey: .simulatorOperationTimeouts) ??
            TestArgFileDefaultValues.simulatorOperationTimeouts
        let simulatorSettings = try container.decodeIfPresent(SimulatorSettings.self, forKey: .simulatorSettings) ??
            TestArgFileDefaultValues.simulatorSettings
        
        let testRunnerTool = try container.decodeIfPresent(TestRunnerTool.self, forKey: .testRunnerTool) ??
            TestArgFileDefaultValues.testRunnerTool
        let testTimeoutConfiguration = try container.decodeIfPresent(TestTimeoutConfiguration.self, forKey: .testTimeoutConfiguration) ??
            TestArgFileDefaultValues.testTimeoutConfiguration
        let workerCapabilityRequirements = try container.decodeIfPresent(Set<WorkerCapabilityRequirement>.self, forKey: .workerCapabilityRequirements) ??
            TestArgFileDefaultValues.workerCapabilityRequirements

        self.init(
            buildArtifacts: buildArtifacts,
            developerDir: developerDir,
            environment: environment,
            numberOfRetries: numberOfRetries,
            pluginLocations: pluginLocations,
            scheduleStrategy: scheduleStrategy,
            simulatorControlTool: simulatorControlTool,
            simulatorOperationTimeouts: simulatorOperationTimeouts,
            simulatorSettings: simulatorSettings,
            testDestination: testDestination,
            testRunnerTool: testRunnerTool,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testType: testType,
            testsToRun: testsToRun,
            workerCapabilityRequirements: workerCapabilityRequirements
        )
    }
}
