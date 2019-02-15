import Foundation

public enum GraphiteClientError: Error, CustomStringConvertible {
    case unableToGetData(from: String)
    case incorrectMetricPath(String)
    case incorrectValue(Double)
    
    public var description: String {
        switch self {
        case .unableToGetData(let from):
            return "Unable to convert string '\(from)' to data"
        case .incorrectMetricPath(let value):
            return "The provided metric path is incorrect: \(value)"
        case .incorrectValue(let value):
            return "The provided metric value is incorrect: \(value)"
        }
    }
}
