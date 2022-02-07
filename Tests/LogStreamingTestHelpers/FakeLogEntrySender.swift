import EmceeLoggingModels
import Dispatch
import Foundation
import LogStreaming
import SocketModels

open class FakeLogEntrySender: LogEntrySender {
    public var invocations = [LogEntry]()
    
    public let socketAddress: SocketAddress
    public var handler: (LogEntry, DispatchQueue) -> Error?
    
    public init(
        socketAddress: SocketAddress,
        handler: @escaping (LogEntry, DispatchQueue) -> Error? = { _, _ in nil }
    ) {
        self.socketAddress = socketAddress
        self.handler = handler
    }
    
    public func send(logEntry: LogEntry, callbackQueue: DispatchQueue, completion: @escaping (Error?) -> ()) {
        invocations.append(logEntry)
        
        let error = self.handler(logEntry, callbackQueue)
        callbackQueue.async {
            completion(error)
        }
    }
}
