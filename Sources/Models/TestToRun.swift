import Foundation

/** An information about test that is requested and expected to be run. */
public enum TestToRun: Decodable, CustomStringConvertible {
    
    /** A test described by string in format: `ClassName/testMethod` */
    case testName(String)
    
    /** A test described by test case id */
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
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            let testName = try container.decode(String.self, forKey: .testName)
            guard testName.components(separatedBy: "/").count == 2, !testName.hasSuffix("()") else {
                throw TestToRunDecodingError.decoding(testName)
            }
            self = .testName(testName)
        } catch {
            let caseId = try container.decode(UInt.self, forKey: .caseId)
            self = .caseId(caseId)
        }
    }
}
