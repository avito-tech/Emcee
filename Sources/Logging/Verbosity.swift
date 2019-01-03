import Ansi
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
    /// Fatal errors that lead to the crash
    case fatal = 100
    /// Always print this log message
    case always = 0
    
    public static func < (left: Verbosity, right: Verbosity) -> Bool {
        return left.rawValue < right.rawValue
    }
    
    public var color: ConsoleColor {
        switch self {
        case .verboseDebug:
            return .none
        case .debug:
            return .none
        case .info:
            return .blue
        case .warning:
            return .yellow
        case .error:
            return .red
        case .fatal:
            return .boldRed
        case .always:
            return .none
        }
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
        case .fatal:
            return "FATAL"
        case .always:
            return "ALWAYS"
        }
    }
}
