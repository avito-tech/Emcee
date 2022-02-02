import Foundation
import EmceeLogging
import EmceeLoggingModels

final class SimpleLogEntryTextFormatter: LogEntryTextFormatter {
    func format(logEntry: LogEntry) -> String {
        var result = ""
        result += "\(logEntry.timestamp)"
        
        if !logEntry.coordinates.isEmpty {
            result += " " + logEntry.coordinates.map { $0.stringValue }.joined(separator: " ")
        }
        
        result += ":"
        result += " \(logEntry.message)"
        
        return result
    }
}
