import Foundation
import Signals

public enum Signal: Hashable, CustomStringConvertible {
    case hup
    case int
    case quit
    case abrt
    case kill
    case alrm
    case term
    case pipe
    case user(Int)
    
    public var description: String {
        switch self {
        case .hup:
            return "SIGHUP"
        case .int:
            return "SIGINT"
        case .quit:
            return "SIGQUIT"
        case .abrt:
            return "SIGABRT"
        case .kill:
            return "SIGKILL"
        case .alrm:
            return "SIGALRM"
        case .term:
            return "SIGTERM"
        case .pipe:
            return "SIGPIPE"
        case .user(let value):
            return "SIGUSR(\(value))"
        }
    }
    
    public var intValue: Int32 {
        switch self {
        case .hup:
            return SIGHUP
        case .int:
            return SIGINT
        case .quit:
            return SIGQUIT
        case .abrt:
            return SIGABRT
        case .kill:
            return SIGKILL
        case .alrm:
            return SIGALRM
        case .term:
            return SIGTERM
        case .pipe:
            return SIGPIPE
        case .user(let value):
            return Int32(value)
        }
    }
    
    internal var blueSignal: Signals.Signal {
        switch self {
        case .hup:
            return .hup
        case .int:
            return .int
        case .quit:
            return .quit
        case .abrt:
            return .abrt
        case .kill:
            return .kill
        case .alrm:
            return .alrm
        case .term:
            return .term
        case .pipe:
            return .pipe
        case .user(let value):
            return .user(value)
        }
    }
}
