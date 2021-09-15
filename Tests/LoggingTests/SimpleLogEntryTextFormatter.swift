import Foundation
import EmceeLogging

final class SimpleLogEntryTextFormatter: LogEntryTextFormatter {
    func format(logEntry: LogEntry) -> String {
        var result = ""
        result += "\(logEntry.timestamp)"
        
        if !logEntry.coordinates.isEmpty {
            result += " " + logEntry.coordinates.joined(separator: " ")
        }
        
        result += ":"
        result += " \(logEntry.message)"
        
        return result
    }
}
