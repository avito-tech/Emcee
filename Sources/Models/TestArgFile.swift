import Foundation

/// Represents --test-arg-file file contents which describes all tests that should be ran.
public struct TestArgFile: Decodable {
    public struct Entry: Decodable, Equatable {
        public let testsToRun: [TestToRun]
        public let buildArtifacts: BuildArtifacts
        public let environment: [String: String]
        public let numberOfRetries: UInt
        public let testDestination: TestDestination
        public let testType: TestType
        public let toolchainConfiguration: ToolchainConfiguration
        
        public init(
            testsToRun: [TestToRun],
            buildArtifacts: BuildArtifacts,
            environment: [String: String],
            numberOfRetries: UInt,
            testDestination: TestDestination,
            testType: TestType,
            toolchainConfiguration: ToolchainConfiguration
        ) {
            self.testsToRun = testsToRun
            self.buildArtifacts = buildArtifacts
            self.environment = environment
            self.numberOfRetries = numberOfRetries
            self.testDestination = testDestination
            self.testType = testType
            self.toolchainConfiguration = toolchainConfiguration
        }
        
        private enum CodingKeys: String, CodingKey {
            case testToRun // TODO: remove, left for backwards compatibility
            case testsToRun
            case environment
            case numberOfRetries
            case testDestination
            case testType
            case buildArtifacts
            case toolchainConfiguration
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let testToRun = try container.decodeIfPresent(TestToRun.self, forKey: .testToRun) {
                testsToRun = [testToRun]
            } else {
                testsToRun = try container.decode([TestToRun].self, forKey: .testsToRun)
            }

            buildArtifacts = try container.decode(BuildArtifacts.self, forKey: .buildArtifacts)
            environment = try container.decodeIfPresent([String: String].self, forKey: .environment) ?? [:]
            numberOfRetries = try container.decode(UInt.self, forKey: .numberOfRetries)
            testDestination = try container.decode(TestDestination.self, forKey: .testDestination)
            testType = try container.decodeIfPresent(TestType.self, forKey: .testType) ?? .uiTest
            toolchainConfiguration = try container.decodeIfPresent(ToolchainConfiguration.self, forKey: .toolchainConfiguration) ?? ToolchainConfiguration(developerDir: .current)
        }
    }
    
    public let entries: [Entry]
    public let scheduleStrategy: ScheduleStrategyType
    
    public init(
        entries: [Entry],
        scheduleStrategy: ScheduleStrategyType
    ) {
        self.entries = entries
        self.scheduleStrategy = scheduleStrategy
    }
}
