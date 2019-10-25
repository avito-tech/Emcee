import Foundation

public enum FbsimctlEventWaitError: Error, CustomStringConvertible {
    case timeoutOccured(FbSimCtlEventName, FbSimCtlEventType)
    case processTerminatedWithoutEvent(pid: Int32, FbSimCtlEventName, FbSimCtlEventType)
    
    public var description: String {
        switch self {
        case .timeoutOccured(let event, let type):
            return "fbsimctl did not produce '\(event.rawValue) - \(type.rawValue)' in time"
        case .processTerminatedWithoutEvent(let pid, let event, let type):
            return "fbsimctl process \(pid) terminated without producing '\(event.rawValue) - \(type.rawValue)' event"
        }
    }
}
