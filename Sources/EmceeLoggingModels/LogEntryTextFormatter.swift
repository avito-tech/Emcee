import Foundation

public protocol LogEntryTextFormatter {
    func format(logEntry: LogEntry) -> String
}
