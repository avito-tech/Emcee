import Foundation

/// Represents --test-arg-file file contents which describes test plan.
public struct TestArgFile: Codable {
    public struct Entry: Codable, Equatable {
        public let buildArtifacts: BuildArtifacts
        public let environment: [String: String]
        public let numberOfRetries: UInt
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
            self.scheduleStrategy = scheduleStrategy
            self.simulatorSettings = simulatorSettings
            self.testDestination = testDestination
            self.testTimeoutConfiguration = testTimeoutConfiguration
            self.testType = testType
            self.testsToRun = testsToRun
            self.toolResources = toolResources
            self.toolchainConfiguration = toolchainConfiguration
        }
        
        private enum CodingKeys: String, CodingKey {
            case buildArtifacts
            case environment
            case numberOfRetries
            case scheduleStrategy
            case simulatorSettings
            case testDestination
            case testTimeoutConfiguration
            case testType
            case testsToRun
            case toolResources
            case toolchainConfiguration
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            buildArtifacts = try container.decode(BuildArtifacts.self, forKey: .buildArtifacts)
            environment = try container.decode([String: String].self, forKey: .environment)
            numberOfRetries = try container.decode(UInt.self, forKey: .numberOfRetries)
            scheduleStrategy = try container.decode(ScheduleStrategyType.self, forKey: .scheduleStrategy)
            simulatorSettings = try container.decode(SimulatorSettings.self, forKey: .simulatorSettings)
            testDestination = try container.decode(TestDestination.self, forKey: .testDestination)
            testTimeoutConfiguration = try container.decode(TestTimeoutConfiguration.self, forKey: .testTimeoutConfiguration)
            testType = try container.decode(TestType.self, forKey: .testType)
            testsToRun = try container.decode([TestToRun].self, forKey: .testsToRun)
            toolResources = try container.decode(ToolResources.self, forKey: .toolResources)
            toolchainConfiguration = try container.decode(ToolchainConfiguration.self, forKey: .toolchainConfiguration)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(buildArtifacts, forKey: .buildArtifacts)
            try container.encode(environment, forKey: .environment)
            try container.encode(numberOfRetries, forKey: .numberOfRetries)
            try container.encode(scheduleStrategy, forKey: .scheduleStrategy)
            try container.encode(simulatorSettings, forKey: .simulatorSettings)
            try container.encode(testDestination, forKey: .testDestination)
            try container.encode(testTimeoutConfiguration, forKey: .testTimeoutConfiguration)
            try container.encode(testType, forKey: .testType)
            try container.encode(testsToRun, forKey: .testsToRun)
            try container.encode(toolResources, forKey: .toolResources)
            try container.encode(toolchainConfiguration, forKey: .toolchainConfiguration)
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
