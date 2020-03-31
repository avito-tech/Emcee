import Foundation

/// An information about test that is requested and expected to be run.
public enum TestToRun: Codable, CustomStringConvertible, Hashable {
    
    /// A single test described by string in format: `ClassName/testMethod`
    case testName(TestName)
    
    /// Run all tests provided by test discovery mechanism
    case allDiscoveredTests
    
    private enum CodingKeys: String, CodingKey {
        case predicateType
        case testName
    }
    
    private enum PredicateType: String, Codable {
        case singleTestName
        case allDiscoveredTests
    }
    
    public var description: String {
        switch self {
        case .testName(let testName):
            return "(\(TestToRun.self) '\(testName))'"
        case .allDiscoveredTests:
            return "(\(TestToRun.self) all discovered tests)"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let predicateType = try container.decode(PredicateType.self, forKey: .predicateType)
        
        switch predicateType {
        case .allDiscoveredTests:
            self = .allDiscoveredTests
        case .singleTestName:
            self = .testName(try container.decode(TestName.self, forKey: .testName))
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .allDiscoveredTests:
            try container.encode(PredicateType.allDiscoveredTests, forKey: .predicateType)
        case .testName(let testName):
            try container.encode(PredicateType.singleTestName, forKey: .predicateType)
            try container.encode(testName, forKey: .testName)
        }
    }
}
