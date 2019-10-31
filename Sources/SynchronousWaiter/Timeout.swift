import Foundation

public struct Timeout: CustomStringConvertible {
    public let description: String
    public let value: TimeInterval

    public init(description: String, value: TimeInterval) {
        self.description = description
        self.value = value
    }
    
    public static var infinity: Timeout {
        return Timeout(description: "Infinite wait will never timeout", value: .infinity)
    }
}

public enum TimeoutError: Error, CustomStringConvertible {
    case waitTimeout(Timeout)
    
    public var description: String {
        switch self {
        case .waitTimeout(let timeout):
            let rounded = (timeout.value * 1000.0).rounded() / 1000.0
            return "Waiter reached timeout of \(rounded) s for '\(timeout.description)' operation"
        }
    }
}
