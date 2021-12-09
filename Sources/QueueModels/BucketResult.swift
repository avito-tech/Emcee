import Foundation

public enum BucketResult: Codable, CustomStringConvertible, Hashable {
    case testingResult(TestingResult)
    
    public var description: String {
        switch self {
        case .testingResult(let testingResult):
            return "\(testingResult)"
        }
    }
}
