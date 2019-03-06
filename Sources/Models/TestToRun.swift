import Foundation

/// An information about test that is requested and expected to be run.
public enum TestToRun: Decodable, CustomStringConvertible, Hashable {
    
    /// A test described by string in format: `ClassName/testMethod`
    case testName(String)
    
    private enum CodingKeys: String, CodingKey {
        case testName
    }
    
    public var description: String {
        switch self {
        case .testName(let testName):
            return "(\(TestToRun.self) '\(testName))'"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = .testName(try container.decode(String.self))
    }
}
