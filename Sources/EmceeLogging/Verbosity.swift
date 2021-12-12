import Foundation

public enum Verbosity: UInt, Comparable {
    /// Detailed debug info suitable for tracing program execution
    case trace = 999
    /// Debug logs
    case debug = 500
    /// User visible logs
    case info = 400
    /// Warnings important for the user
    case warning = 300
    /// Errors important for the user
    case error = 200
    /// Always print this log message
    case always = 0
    
    public static func < (left: Verbosity, right: Verbosity) -> Bool {
        return left.rawValue < right.rawValue
    }
    
    public init?(rawValue: UInt) {
        if rawValue >= Verbosity.trace.rawValue {
            self = .trace
        } else if rawValue >= Verbosity.debug.rawValue {
            self = .debug
        } else if rawValue >= Verbosity.info.rawValue {
            self = .info
        } else if rawValue >= Verbosity.warning.rawValue {
            self = .warning
        } else if rawValue >= Verbosity.error.rawValue {
            self = .error
        } else {
            self = .always
        }
    }
    
    public var stringCode: String {
        switch self {
        case .trace:
            return "TRACE"
        case .debug:
            return "DEBUG"
        case .info:
            return "INFO"
        case .warning:
            return "WARNING"
        case .error:
            return "ERROR"
        case .always:
            return "ALWAYS"
        }
    }
}
