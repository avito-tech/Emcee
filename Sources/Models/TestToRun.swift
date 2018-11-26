import Foundation

/// An information about test that is requested and expected to be run.
public enum TestToRun: Decodable, CustomStringConvertible, Hashable {
    
    /// A test described by string in format: `ClassName/testMethod`
    case testName(String)
    
    /// A test described by test case id
    case caseId(UInt)
    
    private enum CodingKeys: String, CodingKey {
        case testName
        case caseId
    }
    
    public var description: String {
        switch self {
        case .testName(let testName):
            return "(\(TestToRun.self) '\(testName))'"
        case .caseId(let caseId):
            return "(\(TestToRun.self) caseId = \(caseId))"
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        do {
            self = .testName(try container.decode(String.self))
        } catch {
            self = .caseId(try container.decode(UInt.self))
        }
    }
}
