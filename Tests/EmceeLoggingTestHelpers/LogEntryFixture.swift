import Foundation
import EmceeLoggingModels

open class LogEntryFixture {
    public var file: String = "file"
    public var line: UInt = 42
    public var coordinates: [LogEntryCoordinate] = []
    public var message: String = "message"
    public var timestamp: Date = Date(timeIntervalSince1970: 1000)
    public var verbosity: Verbosity = .debug
    
    public init(
        file: String = "file",
        line: UInt = 42,
        coordinates: [LogEntryCoordinate] = [],
        message: String = "message",
        timestamp: Date = Date(timeIntervalSince1970: 1000),
        verbosity: Verbosity = .debug
    ) {
        self.file = file
        self.line = line
        self.coordinates = coordinates
        self.message = message
        self.timestamp = timestamp
        self.verbosity = verbosity
    }
    
    public func logEntry() -> LogEntry {
        LogEntry(
            file: file,
            line: line,
            coordinates: coordinates,
            message: message,
            timestamp: timestamp,
            verbosity: verbosity
        )
    }
}
