import EmceeLogging
import EmceeLoggingModels
import Foundation

public protocol LogStreamer {
    /// Broadcasts the given log entry to all recipients.
    func stream(
        logEntry: LogEntry
    )
}
