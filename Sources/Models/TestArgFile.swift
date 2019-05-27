import Foundation

/// Represents --test-arg-file file contents which describes all tests that should be ran.
public struct TestArgFile: Decodable {
    public struct Entry: Decodable, Equatable {
        public let testToRun: TestToRun
        public let environment: [String: String]
        public let numberOfRetries: UInt
        public let testDestination: TestDestination
        public let testType: TestType
        public let buildArtifacts: BuildArtifacts
        
        public init(
            testToRun: TestToRun,
            environment: [String: String],
            numberOfRetries: UInt,
            testDestination: TestDestination,
            testType: TestType,
            buildArtifacts: BuildArtifacts
        ) {
            self.testToRun = testToRun
            self.environment = environment
            self.numberOfRetries = numberOfRetries
            self.testDestination = testDestination
            self.testType = testType
            self.buildArtifacts = buildArtifacts
        }
        
        private enum CodingKeys: String, CodingKey {
            case testToRun
            case environment
            case numberOfRetries
            case testDestination
            case testType
            case buildArtifacts
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            testToRun = try container.decode(TestToRun.self, forKey: .testToRun)
            environment = try container.decodeIfPresent([String: String].self, forKey: .environment) ?? [:]
            numberOfRetries = try container.decode(UInt.self, forKey: .numberOfRetries)
            testDestination = try container.decode(TestDestination.self, forKey: .testDestination)
            testType = try container.decodeIfPresent(TestType.self, forKey: .testType) ?? .uiTest
            buildArtifacts = try container.decode(BuildArtifacts.self, forKey: .buildArtifacts)
        }
    }
    
    public let entries: [Entry]
    
    public init(entries: [Entry]) {
        self.entries = entries
    }
}
