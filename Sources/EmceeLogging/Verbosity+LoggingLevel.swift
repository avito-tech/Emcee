import Foundation
import Logging

extension Verbosity {
    var level: Logging.Logger.Level {
        switch self {
        case .trace:
            return .trace
        case .debug:
            return .debug
        case .info:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .always:
            return .info
        }
    }
}
