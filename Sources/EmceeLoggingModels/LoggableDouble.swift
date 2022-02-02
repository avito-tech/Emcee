import Foundation

public final class LoggableDouble: CustomStringConvertible {
    private let value: Double
    private let suffix: String
    
    public init(_ value: Double, suffix: String) {
        self.value = value
        self.suffix = suffix
    }
    
    public var description: String {
        let string = String(format: "%.3f", value)
        return [string, suffix].filter { !$0.isEmpty }.joined(separator: " ")
    }
}

extension TimeInterval {
    public func loggableInSeconds() -> LoggableDouble {
        loggable(suffix: "sec")
    }
    
    public func loggable(suffix: String) -> LoggableDouble {
        LoggableDouble(self, suffix: suffix)
    }
}
