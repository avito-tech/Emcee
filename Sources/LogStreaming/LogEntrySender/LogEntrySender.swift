import Dispatch
import EmceeLoggingModels
import Foundation

public protocol LogEntrySender {
    func send(
        logEntry: LogEntry,
        callbackQueue: DispatchQueue,
        completion: @escaping (Error?) -> ()
    )
}
