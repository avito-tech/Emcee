import AtomicModels
import DateProvider
import EmceeExtensions
import EmceeLoggingModels
import Foundation

public final class FileHandleLoggerHandler: LoggerHandler {
    private let dateProvider: DateProvider
    private let fileState: AtomicValue<FileState>
    private let verbosity: Verbosity
    private let logEntryTextFormatter: LogEntryTextFormatter
    private let fileHandleShouldBeClosed: Bool
    private let skipMetadataFlag: SkipMetadataFlags?
    private let coordinateNamesToSkipFromTextualOutput: Set<String>
    
    public enum SkipMetadataFlags: String {
        case skipStdOutput
        case skipFileOutput
    }

    public init(
        dateProvider: DateProvider,
        fileHandle: FileHandle,
        verbosity: Verbosity,
        logEntryTextFormatter: LogEntryTextFormatter,
        fileHandleShouldBeClosed: Bool,
        skipMetadataFlag: SkipMetadataFlags?,
        coordinateNamesToSkipFromTextualOutput: Set<String> = ContextualLogger.ContextKeys.stringSetForAllRawValues()
    ) {
        self.dateProvider = dateProvider
        self.fileState = AtomicValue(FileState.open(fileHandle))
        self.verbosity = verbosity
        self.logEntryTextFormatter = logEntryTextFormatter
        self.fileHandleShouldBeClosed = fileHandleShouldBeClosed
        self.skipMetadataFlag = skipMetadataFlag
        self.coordinateNamesToSkipFromTextualOutput = coordinateNamesToSkipFromTextualOutput
    }
    
    public func handle(logEntry: LogEntry) {
        guard logEntry.verbosity <= verbosity else { return }
        
        if let skipMetadataFlag = skipMetadataFlag, logEntry.coordinates.contains(where: { $0.name == skipMetadataFlag.rawValue }) {
            return
        }
        
        var coordinates = logEntry.coordinates.filter {
            !coordinateNamesToSkipFromTextualOutput.contains($0.name)
        }
        
        if let subprocessId = logEntry.coordinate(name: ContextualLogger.ContextKeys.subprocessId.rawValue)?.value {
            if let xcrunToolName = logEntry.coordinate(name: ContextualLogger.ContextKeys.xcrunToolName.rawValue)?.value {
                coordinates.append(LogEntryCoordinate(name: xcrunToolName, value: "\(subprocessId)"))
            } else if let subprocessName = logEntry.coordinate(name: ContextualLogger.ContextKeys.subprocessName.rawValue)?.value {
                coordinates.append(LogEntryCoordinate(name: subprocessName, value: "\(subprocessId)"))
            }
        }
        
        let logEntry = logEntry.with(coordinates: coordinates)
        
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
}

extension ContextualLogger {
    public var skippingStdOutput: ContextualLogger {
        withMetadata(key: FileHandleLoggerHandler.SkipMetadataFlags.skipStdOutput.rawValue, value: nil)
    }
    
    public var skippingFileLogOutput: ContextualLogger {
        withMetadata(key: FileHandleLoggerHandler.SkipMetadataFlags.skipFileOutput.rawValue, value: nil)
    }
}
