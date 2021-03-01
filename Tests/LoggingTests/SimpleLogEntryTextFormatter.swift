import Foundation
import EmceeLogging

final class SimpleLogEntryTextFormatter: LogEntryTextFormatter {
    func format(logEntry: LogEntry) -> String {
        return "\(logEntry.timestamp): \(logEntry.message)"
    }
}
