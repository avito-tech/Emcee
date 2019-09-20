import Foundation

/// Represents --test-arg-file file contents which describes all tests that should be ran.
public struct TestArgFile: Codable {
    public struct Entry: Codable, Equatable {
        public let testsToRun: [TestToRun]
        public let buildArtifacts: BuildArtifacts
        public let environment: [String: String]
        public let numberOfRetries: UInt
        public let scheduleStrategy: ScheduleStrategyType
        public let testDestination: TestDestination
        public let testType: TestType
        public let toolchainConfiguration: ToolchainConfiguration
        
        public init(
            testsToRun: [TestToRun],
            buildArtifacts: BuildArtifacts,
            environment: [String: String],
            numberOfRetries: UInt,
            scheduleStrategy: ScheduleStrategyType,
            testDestination: TestDestination,
            testType: TestType,
            toolchainConfiguration: ToolchainConfiguration
        ) {
            self.testsToRun = testsToRun
            self.buildArtifacts = buildArtifacts
            self.environment = environment
            self.numberOfRetries = numberOfRetries
            self.scheduleStrategy = scheduleStrategy
            self.testDestination = testDestination
            self.testType = testType
            self.toolchainConfiguration = toolchainConfiguration
        }
        
        private enum CodingKeys: String, CodingKey {
            case testsToRun
            case environment
            case numberOfRetries
            case scheduleStrategy
            case testDestination
            case testType
            case buildArtifacts
            case toolchainConfiguration
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            testsToRun = try container.decode([TestToRun].self, forKey: .testsToRun)
            buildArtifacts = try container.decode(BuildArtifacts.self, forKey: .buildArtifacts)
            environment = try container.decodeIfPresent([String: String].self, forKey: .environment) ?? [:]
            numberOfRetries = try container.decode(UInt.self, forKey: .numberOfRetries)
            scheduleStrategy = try container.decode(ScheduleStrategyType.self, forKey: .scheduleStrategy)
            testDestination = try container.decode(TestDestination.self, forKey: .testDestination)
            testType = try container.decodeIfPresent(TestType.self, forKey: .testType) ?? .uiTest
            toolchainConfiguration = try container.decode(ToolchainConfiguration.self, forKey: .toolchainConfiguration)
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            try container.encode(testsToRun, forKey: .testsToRun)
            try container.encode(buildArtifacts, forKey: .buildArtifacts)
            try container.encode(environment, forKey: .environment)
            try container.encode(numberOfRetries, forKey: .numberOfRetries)
            try container.encode(testDestination, forKey: .testDestination)
            try container.encode(testType, forKey: .testType)
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
