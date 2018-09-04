import Foundation

public enum FbsimctlEventWaitError: Error, CustomStringConvertible {
    case timeoutOccured(FbSimCtlEventName, FbSimCtlEventType)
    case processTerminatedWithoutEvent(FbSimCtlEventName, FbSimCtlEventType)
    
    public var description: String {
        switch self {
        case .timeoutOccured(let event, let type):
            return "fbsimctl did not produce '\(event.rawValue) - \(type.rawValue)' in time"
        case .processTerminatedWithoutEvent(let event, let type):
            return "fbsimctl process terminated without producing '\(event.rawValue) - \(type.rawValue)' event"
        }
    }
}
