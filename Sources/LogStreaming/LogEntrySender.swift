import Dispatch
import EmceeLogging
import EmceeLoggingModels
import Foundation
import RESTMethods

public protocol LogEntrySender {
    func send(
        logEntry: LogEntry,
        callbackQueue: DispatchQueue,
        completion: @escaping (Error?) -> ()
    )
}
