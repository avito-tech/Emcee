import Foundation

public final class LoggableDuration: CustomStringConvertible {
    private let duration: TimeInterval
    private let suffix: String
    
    public init(_ duration: TimeInterval, suffix: String = "sec") {
        self.duration = duration
        self.suffix = suffix
    }
    
    public var description: String {
        let durationString = String(format: "%.3f", duration)
        return [durationString, suffix].filter { !$0.isEmpty }.joined(separator: " ")
    }
}
