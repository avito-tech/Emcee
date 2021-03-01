import Foundation
import EmceeLogging
import Logging

public final class FakeLoggerHandle: LoggerHandler {
    public subscript(metadataKey _: String) -> Logging.Logger.Metadata.Value? {
        get { nil }
        set(newValue) { }
    }
    
    public var metadata: Logging.Logger.Metadata = [:]
    
    public var logLevel: Logging.Logger.Level = .debug
    
    public var logEntries = [LogEntry]()
    public func handle(logEntry: LogEntry) {
        logEntries.append(logEntry)
    }
    public func tearDownLogging(timeout: TimeInterval) {}
}
