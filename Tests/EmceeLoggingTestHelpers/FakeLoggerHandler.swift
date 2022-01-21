import DateProvider
import DateProviderTestHelpers
import Foundation
import EmceeLogging
import EmceeLoggingModels

public final class FakeLoggerHandle: LoggerHandler {
    public var dateProviderFixture = DateProviderFixture()
    public var dateProvider: DateProvider { dateProviderFixture }
    
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
