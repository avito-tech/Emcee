import Foundation

public final class AggregatedLoggerHandler: LoggerHandler {
    private let handlers: [LoggerHandler]
    
    public init(handlers: [LoggerHandler]) {
        self.handlers = handlers
    }
    
    public func handle(logEntry: LogEntry) {
        for handler in handlers {
            handler.handle(logEntry: logEntry)
        }
    }
    
    public func byAdding(handler: LoggerHandler) -> AggregatedLoggerHandler {
        let newHandlers = handlers + [handler]
        return AggregatedLoggerHandler(handlers: newHandlers)
    }
    
    public func tearDownLogging() {
        for handler in handlers {
            handler.tearDownLogging()
        }
    }
}
