import Foundation
import Logging

public final class FakeLoggerHandle: LoggerHandler {
    public var logEntries = [LogEntry]()
    public func handle(logEntry: LogEntry) {
        logEntries.append(logEntry)
    }
    public func tearDownLogging(timeout: TimeInterval) {}
}
