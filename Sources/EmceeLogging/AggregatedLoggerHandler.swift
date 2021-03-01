import Dispatch
import Foundation

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
}
