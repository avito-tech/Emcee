import AtomicModels
import EmceeLogging
import EmceeLoggingModels
import Foundation

public final class InMemoryLogStreamer: LogStreamer {
    public init() {}
    
    private let storage = AtomicValue<[LogEntry]>([])
    
    public func stream(logEntry: LogEntry) {
        storage.withExclusiveAccess {
            $0.append(logEntry)
        }
    }
    
    public func logEntries() -> [LogEntry] {
        return storage.currentValue()
    }
}
