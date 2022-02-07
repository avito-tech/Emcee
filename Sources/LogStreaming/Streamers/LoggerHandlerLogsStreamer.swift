import EmceeLogging
import EmceeLoggingModels
import Foundation

/// Directly streams log entries into provided `LoggerHandler`
public final class LoggerHandlerLogStreamer: LogStreamer {
    private let loggerHandler: LoggerHandler
    
    public init(loggerHandler: LoggerHandler) {
        self.loggerHandler = loggerHandler
    }
    
    public func stream(logEntry: LogEntry) {
        loggerHandler.handle(logEntry: logEntry)
    }
}
