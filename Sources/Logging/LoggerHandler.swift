import Foundation

public protocol LoggerHandler {
    func handle(logEntry: LogEntry)
    func tearDownLogging()
}
