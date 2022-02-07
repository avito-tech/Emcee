import EmceeLogging
import EmceeLoggingModels
import Foundation

public final class NoOpLogStreamer: LogStreamer {
    public static let instance = NoOpLogStreamer()
    
    private init() {}
    
    public func stream(logEntry: LogEntry) {}
}
