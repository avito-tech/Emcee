import EmceeLogging
import EmceeLoggingModels
import Foundation
import QueueClient
import QueueModels
import RESTMethods

public final class SendLogsToQueueLoggerHandler: LoggerHandler {
    private let logEntrySender: LogEntrySender
    private let logger: ContextualLogger
    
    private let queue = DispatchQueue(label: "SendLogsToQueueLoggerHandler.queue")
    private let group = DispatchGroup()
    
    public enum SkipMetadataFlags: String {
        case skipLoggingIntoQueue
    }
    
    public init(
        logEntrySender: LogEntrySender,
        logger: ContextualLogger
    ) {
        self.logEntrySender = logEntrySender
        self.logger = logger.skippingLoggingToQueue
    }
    
    public func handle(logEntry: LogEntry) {
        if logEntry.coordinates.contains(where: { $0.name == SkipMetadataFlags.skipLoggingIntoQueue.rawValue }) {
            return
        }
        
        group.enter()
        
        logEntrySender.send(
            logEntry: logEntry,
            callbackQueue: queue
        ) { [group, logger] error in
            if let error = error {
                logger.warning("Failed to send log message to queue: \(error)")
            }
            
            group.leave()
        }
    }
    
    public func tearDownLogging(timeout: TimeInterval) {
        _ = group.wait(timeout: .now() + timeout)
    }
}

extension ContextualLogger {
    /// Worker logs will not be sent into queue
    public var skippingLoggingToQueue: ContextualLogger {
        withMetadata(key: SendLogsToQueueLoggerHandler.SkipMetadataFlags.skipLoggingIntoQueue.rawValue, value: "true")
    }
}
