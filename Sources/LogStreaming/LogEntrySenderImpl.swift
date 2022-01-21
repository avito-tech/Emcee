import Dispatch
import Foundation
import EmceeLogging
import EmceeLoggingModels
import RESTMethods
import RequestSender
import Types

public final class LogEntrySenderImpl: LogEntrySender {
    private let requestSender: RequestSender
    private let requestsTimeout = 10.0
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func send(logEntry: LogEntry, callbackQueue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        requestSender.sendRequestWithCallback(
            request: LogEntryNetworkRequest(
                payload: logEntry,
                timeout: requestsTimeout
            ),
            callbackQueue: callbackQueue
        ) { (requestResult: Either<VoidPayload, RequestSenderError>) in
            completion(requestResult.right)
        }
    }
}
