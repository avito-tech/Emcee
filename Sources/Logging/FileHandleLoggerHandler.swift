import Extensions
import Foundation

public final class FileHandleLoggerHandler: LoggerHandler {
    private let fileHandle: FileHandle
    private let verbosity: Verbosity
    private let logEntryTextFormatter: LogEntryTextFormatter
    private let supportsAnsiColors: Bool

    public init(
        fileHandle: FileHandle,
        verbosity: Verbosity,
        logEntryTextFormatter: LogEntryTextFormatter,
        supportsAnsiColors: Bool)
    {
        self.fileHandle = fileHandle
        self.verbosity = verbosity
        self.logEntryTextFormatter = logEntryTextFormatter
        self.supportsAnsiColors = supportsAnsiColors
    }
    
    public func handle(logEntry: LogEntry) {
        guard logEntry.verbosity <= verbosity else { return }
        
        var text = logEntryTextFormatter.format(logEntry: logEntry)
        if supportsAnsiColors {
            text = text.with(consoleColor: logEntry.color ?? logEntry.verbosity.color)
        }
        
        var fileHandle = self.fileHandle
        print(text, to: &fileHandle)
    }
}
