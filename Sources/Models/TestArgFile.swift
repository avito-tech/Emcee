import Foundation

/// Represents --test-arg-file file contents which describes test plan.
public struct TestArgFile: Codable {
    public struct Entry: Codable, Equatable {
        public let buildArtifacts: BuildArtifacts
        public let environment: [String: String]
        public let numberOfRetries: UInt
        public let pluginLocations: Set<PluginLocation>
        public let scheduleStrategy: ScheduleStrategyType
        public let simulatorSettings: SimulatorSettings
        public let testDestination: TestDestination
        public let testTimeoutConfiguration: TestTimeoutConfiguration
        public let testType: TestType
        public let testsToRun: [TestToRun]
        public let toolResources: ToolResources
        public let toolchainConfiguration: ToolchainConfiguration
        
        public init(
            buildArtifacts: BuildArtifacts,
            environment: [String: String],
            numberOfRetries: UInt,
            pluginLocations: Set<PluginLocation>,
            scheduleStrategy: ScheduleStrategyType,
            simulatorSettings: SimulatorSettings,
            testDestination: TestDestination,
            testTimeoutConfiguration: TestTimeoutConfiguration,
            testType: TestType,
            testsToRun: [TestToRun],
            toolResources: ToolResources,
            toolchainConfiguration: ToolchainConfiguration
        ) {
            self.buildArtifacts = buildArtifacts
            self.environment = environment
            self.numberOfRetries = numberOfRetries
            self.pluginLocations = pluginLocations
            self.scheduleStrategy = scheduleStrategy
            self.simulatorSettings = simulatorSettings
            self.testDestination = testDestination
            self.testTimeoutConfiguration = testTimeoutConfiguration
            self.testType = testType
            self.testsToRun = testsToRun
            self.toolResources = toolResources
            self.toolchainConfiguration = toolchainConfiguration
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
