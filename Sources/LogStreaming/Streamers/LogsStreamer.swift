import EmceeLogging
import EmceeLoggingModels
import Foundation

public protocol LogStreamer {
    func stream(
        logEntry: LogEntry
    )
}
