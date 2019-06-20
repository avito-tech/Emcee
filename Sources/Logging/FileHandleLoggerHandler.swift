import AtomicModels
import Extensions
import Foundation

public final class FileHandleLoggerHandler: LoggerHandler {    
    private let fileState: AtomicValue<FileState>
    private let verbosity: Verbosity
    private let logEntryTextFormatter: LogEntryTextFormatter
    private let supportsAnsiColors: Bool
    private let fileHandleShouldBeClosed: Bool

    public init(
        fileHandle: FileHandle,
        verbosity: Verbosity,
        logEntryTextFormatter: LogEntryTextFormatter,
        supportsAnsiColors: Bool,
        fileHandleShouldBeClosed: Bool
    ) {
        self.fileState = AtomicValue(FileState.open(fileHandle))
        self.verbosity = verbosity
        self.logEntryTextFormatter = logEntryTextFormatter
        self.supportsAnsiColors = supportsAnsiColors
        self.fileHandleShouldBeClosed = fileHandleShouldBeClosed
    }
    
    public func handle(logEntry: LogEntry) {
        guard logEntry.verbosity <= verbosity else { return }
        
        var text = logEntryTextFormatter.format(logEntry: logEntry)
        if supportsAnsiColors {
            text = text.with(consoleColor: logEntry.color ?? logEntry.verbosity.color)
        }
        
        _ = fileState.withExclusiveAccess { fileState in
            guard var fileHandle = fileState.openedFileHandle else { return }
            print(text, to: &fileHandle)
        }
    }
    
    public func tearDownLogging(timeout: TimeInterval) {
        _ = fileState.withExclusiveAccess { fileState in
            if fileHandleShouldBeClosed {
                fileState.close()
            }
        }
    }
}
