import AtomicModels
import DateProvider
import Extensions
import Foundation
import Logging

public final class FileHandleLoggerHandler: LoggerHandler {
    private let dateProvider: DateProvider
    private let fileState: AtomicValue<FileState>
    private let verbosity: Verbosity
    private let logEntryTextFormatter: LogEntryTextFormatter
    private let fileHandleShouldBeClosed: Bool
    private let skipMetadataFlag: SkipMetadataFlag?
    
    public enum SkipMetadataFlag: String {
        case skipStdOutput
        case skipFileOutput
    }

    public init(
        dateProvider: DateProvider,
        fileHandle: FileHandle,
        verbosity: Verbosity,
        logEntryTextFormatter: LogEntryTextFormatter,
        fileHandleShouldBeClosed: Bool,
        skipMetadataFlag: SkipMetadataFlag?
    ) {
        self.dateProvider = dateProvider
        self.fileState = AtomicValue(FileState.open(fileHandle))
        self.verbosity = verbosity
        self.logEntryTextFormatter = logEntryTextFormatter
        self.fileHandleShouldBeClosed = fileHandleShouldBeClosed
        self.logLevel = verbosity.level
        self.skipMetadataFlag = skipMetadataFlag
    }
    
    public func handle(logEntry: LogEntry) {
        guard logEntry.verbosity <= verbosity else { return }
        
        let text = logEntryTextFormatter.format(logEntry: logEntry)
        fileState.withExclusiveAccess { fileState in
            guard var fileHandle = fileState.openedFileHandle else { return }
            print(text, to: &fileHandle)
        }
    }
    
    public func tearDownLogging(timeout: TimeInterval) {
        fileState.withExclusiveAccess { fileState in
            if fileHandleShouldBeClosed {
                fileState.close()
            }
        }
    }
    
    public func log(
        level: Logging.Logger.Level,
        message: Logging.Logger.Message,
        metadata: Logging.Logger.Metadata?,
        source: String,
        file: String,
        function: String,
        line: UInt
    ) {
        if let skipMetadataFlag = skipMetadataFlag, metadata?[skipMetadataFlag.rawValue] != nil { return }
        
        let entry = LogEntry(
            file: file,
            line: line,
            coordinates: [],
            message: message.description,
            timestamp: dateProvider.currentDate(),
            verbosity: level.verbosity
        )
        handle(logEntry: entry)
    }
    
    public var logLevel: Logging.Logger.Level
    
    public var metadata: Logging.Logger.Metadata = [:]
    
    public subscript(metadataKey _: String) -> Logging.Logger.Metadata.Value? {
        get {
            return nil
        }
        set(newValue) {
            
        }
    }
}

extension Logging.Logger.Level {
    var verbosity: Verbosity {
        switch self {
        case .trace:
            return .verboseDebug
        case .debug:
            return .debug
        case .info:
            return .info
        case .notice:
            return .info
        case .warning:
            return .warning
        case .error:
            return .error
        case .critical:
            return .error
        }
    }
}
