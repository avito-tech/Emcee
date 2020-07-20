import BuildArtifacts
import DeveloperDirModels
import Foundation
import Models
import PluginSupport
import QueueModels
import ScheduleStrategy
import SimulatorPoolModels
import RunnerModels

/// Represents --test-arg-file file contents which describes test plan.
public struct TestArgFile: Codable {
    public struct Entry: Codable, Equatable {
        public let buildArtifacts: BuildArtifacts
        public let developerDir: DeveloperDir
        public let environment: [String: String]
        public let numberOfRetries: UInt
        public let pluginLocations: Set<PluginLocation>
        public let scheduleStrategy: ScheduleStrategyType
        public let simulatorControlTool: SimulatorControlTool
        public let simulatorOperationTimeouts: SimulatorOperationTimeouts
        public let simulatorSettings: SimulatorSettings
        public let testDestination: TestDestination
        public let testRunnerTool: TestRunnerTool
        public let testTimeoutConfiguration: TestTimeoutConfiguration
        public let testType: TestType
        public let testsToRun: [TestToRun]
        
        public init(
            buildArtifacts: BuildArtifacts,
            developerDir: DeveloperDir,
            environment: [String: String],
            numberOfRetries: UInt,
            pluginLocations: Set<PluginLocation>,
            scheduleStrategy: ScheduleStrategyType,
            simulatorControlTool: SimulatorControlTool,
            simulatorOperationTimeouts: SimulatorOperationTimeouts,
            simulatorSettings: SimulatorSettings,
            testDestination: TestDestination,
            testRunnerTool: TestRunnerTool,
            testTimeoutConfiguration: TestTimeoutConfiguration,
            testType: TestType,
            testsToRun: [TestToRun]
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
        }
    }
    
    public let entries: [Entry]
    public let priority: Priority
    public let testDestinationConfigurations: [TestDestinationConfiguration]
    
    public init(
        entries: [Entry],
        priority: Priority,
        testDestinationConfigurations: [TestDestinationConfiguration]
    ) {
        self.entries = entries
        self.priority = priority
        self.testDestinationConfigurations = testDestinationConfigurations
    }
}
