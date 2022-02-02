import Foundation
import EmceeLogging
import EmceeLoggingModels

public final class FakeLoggerHandle: LoggerHandler {
    public init() {}
    
    public var logEntries = [LogEntry]()
    
    public func handle(logEntry: LogEntry) {
        logEntries.append(logEntry)
    }
    
    public var tornDown = false
    public func tearDownLogging(timeout: TimeInterval) {
        tornDown = true
    }
}
