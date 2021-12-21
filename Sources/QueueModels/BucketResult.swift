import Foundation

public enum BucketResult: Codable, CustomStringConvertible, Hashable {
    case testingResult(TestingResult)
    case pong
    
    public var description: String {
        switch self {
        case .testingResult(let testingResult):
            return "\(testingResult)"
        case .pong:
            return "pong"
        }
    }
}
