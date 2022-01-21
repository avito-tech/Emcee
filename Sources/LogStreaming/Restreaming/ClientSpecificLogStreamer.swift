import Dispatch
import EmceeLogging
import EmceeLoggingModels
import Foundation
import SocketModels

public final class ClientSpecificLogStreamer: LogStreamer {
    private let clientRestSocketAddress: SocketAddress
    private let logEntrySenderProvider: LogEntrySenderProvider
    private let queue: DispatchQueue
    private let willSendLogEntry: () -> ()
    private let didSendLogEntry: (Error?) -> ()
    
    public init(
        clientRestSocketAddress: SocketAddress,
        logEntrySenderProvider: LogEntrySenderProvider,
        queue: DispatchQueue,
        willSendLogEntry: @escaping () -> (),
        didSendLogEntry: @escaping (Error?) -> ()
    ) {
        self.clientRestSocketAddress = clientRestSocketAddress
        self.logEntrySenderProvider = logEntrySenderProvider
        self.queue = queue
        self.willSendLogEntry = willSendLogEntry
        self.didSendLogEntry = didSendLogEntry
    }
    
    public func stream(logEntry: LogEntry) {
        let logEntrySender = logEntrySenderProvider.create(
            socketAddress: clientRestSocketAddress
        )
        
        willSendLogEntry()
        
        logEntrySender.send(
            logEntry: logEntry,
            callbackQueue: queue,
            completion: didSendLogEntry
        )
    }
}
