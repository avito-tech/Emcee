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
}
