import Foundation
import Logging

public protocol LoggerHandler: LogHandler {
    func handle(logEntry: LogEntry)
    func tearDownLogging(timeout: TimeInterval)
}
