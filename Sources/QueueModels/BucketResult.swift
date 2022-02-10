import CommonTestModels
import Foundation

public enum BucketResult: Codable, CustomStringConvertible, Hashable {
    case testingResult(TestingResult)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        self = .testingResult(try container.decode(TestingResult.self))
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .testingResult(let testingResult):
            try container.encode(testingResult)
        }
    }
    
    public var description: String {
        switch self {
        case .testingResult(let testingResult):
            return "\(testingResult)"
        }
    }
}
