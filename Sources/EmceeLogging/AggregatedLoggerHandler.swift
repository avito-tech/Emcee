import Dispatch
import Foundation
import Logging

public final class AggregatedLoggerHandler: LoggerHandler {
    private let handlers: [LoggerHandler]
    private let syncQueue = DispatchQueue(label: "ru.avito.emcee.AggregatedLoggerHandler.syncQueue")
    
    public init(handlers: [LoggerHandler]) {
        self.handlers = handlers
    }
    
    public func handle(logEntry: LogEntry) {
        for handler in allHandlers_safe {
            handler.handle(logEntry: logEntry)
        }
    }
    
    public func byAdding(handler: LoggerHandler) -> AggregatedLoggerHandler {
        let newHandlers = allHandlers_safe + [handler]
        return AggregatedLoggerHandler(handlers: newHandlers)
    }
    
    private var allHandlers_safe: [LoggerHandler] {
        return syncQueue.sync { handlers }
    }
    
    public func tearDownLogging(timeout: TimeInterval) {
        for handler in allHandlers_safe {
            syncQueue.async {
                handler.tearDownLogging(timeout: timeout)
            }
        }
    }
    
    public func log(level: Logging.Logger.Level, message: Logging.Logger.Message, metadata: Logging.Logger.Metadata?, source: String, file: String, function: String, line: UInt) {
        for handler in allHandlers_safe {
            handler.log(level: level, message: message, metadata: metadata, source: source, file: file, function: function, line: line)
        }
    }
    
    // LogHandler
    
    public subscript(metadataKey _: String) -> Logging.Logger.Metadata.Value? {
        get { nil }
        set(newValue) { }
    }
    
    public var metadata: Logging.Logger.Metadata = [:]
    public var logLevel: Logging.Logger.Level = .debug
}
