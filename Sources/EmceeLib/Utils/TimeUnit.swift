import Foundation

public enum TimeUnit {
    case seconds(Double)
    case minutes(Double)
    case hours(Double)
    case days(Double)
    
    public var timeInterval: TimeInterval {
        switch self {
        case .seconds(let value):
            return value
        case .minutes(let value):
            return value * 60
        case .hours(let value):
            return value * 60 * 60
        case .days(let value):
            return value * 60 * 60 * 24
        }
    }
}
