import Foundation

public enum Verbosity: UInt, Comparable {
    /// Detailed debug info
    case verboseDebug = 999
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
    
    public var stringCode: String {
        switch self {
        case .verboseDebug:
            return "VERBOSE"
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
