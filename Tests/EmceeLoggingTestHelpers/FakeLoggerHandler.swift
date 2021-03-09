import Foundation
import EmceeLogging
import Logging

public final class FakeLoggerHandle: LoggerHandler {
    public init() {}
    
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
    
    public var logCalls: [(message: String, metadata: Logging.Logger.Metadata?)] = []
    public func log(
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata: Logging.Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        logCalls.append((message: "\(message)", metadata: metadata))
    }
}
