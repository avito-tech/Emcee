import EmceeLoggingModels
import Foundation
import LogStreaming
import XCTest

open class FakeLogStreamer: LogStreamer {
    public init() {}
    
    public var capturedLogEntries = [LogEntry]()
    
    public func stream(logEntry: LogEntry) {
        capturedLogEntries.append(logEntry)
    }
}
