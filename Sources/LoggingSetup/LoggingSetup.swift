import Ansi
import Basic
import Dispatch
import Foundation
import LocalHostDeterminer
import Logging

public final class LoggingSetup {
    private init() {}
    
    public static func setupLogging(stderrVerbosity: Verbosity) throws {
        let filename = "pid_\(ProcessInfo.processInfo.processIdentifier)"
        let detailedLogPath = try TemporaryFile(
            dir: AbsolutePath(validating: try logsContainerFolderUrl().path),
            prefix: filename,
            suffix: ".log",
            deleteOnClose: false
        )
        
        GlobalLoggerConfig.loggerHandler = AggregatedLoggerHandler(
            handlers: createLoggerHandlers(
                stderrVerbosity: stderrVerbosity,
                detaildLogFileHandle: detailedLogPath.fileHandle
            )
        )
        Logger.always("Logging verbosity level is set to \(stderrVerbosity.stringCode)")
        Logger.always("To fetch detailed verbose log:")
        Logger.always("$ scp \(LocalHostDeterminer.currentHostAddress):\(detailedLogPath.path.asString) /tmp/\(filename).log")
    }
    
    private static func createLoggerHandlers(
        stderrVerbosity: Verbosity,
        detaildLogFileHandle: FileHandle)
        -> [LoggerHandler]
    {
        return [
            createStderrInfoLoggerHandler(verbosity: stderrVerbosity),
            createDetailedLoggerHandler(fileHandle: detaildLogFileHandle)
        ]
    }
    
    private static func createStderrInfoLoggerHandler(verbosity: Verbosity) -> LoggerHandler {
        return FileHandleLoggerHandler(
            fileHandle: FileHandle.standardError,
            verbosity: verbosity,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            supportsAnsiColors: true
        )
    }
    
    private static func createDetailedLoggerHandler(fileHandle: FileHandle) -> LoggerHandler {
        return FileHandleLoggerHandler(
            fileHandle: fileHandle,
            verbosity: Verbosity.verboseDebug,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            supportsAnsiColors: false
        )
    }
    
    private static func logsContainerFolderUrl() throws -> URL {
        let libraryUrl = try FileManager.default.url(
            for: .libraryDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let container = libraryUrl
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("ru.avito.emcee.logs", isDirectory: true)
            .appendingPathComponent(ProcessInfo.processInfo.processName, isDirectory: true)
        try FileManager.default.createDirectory(at: container, withIntermediateDirectories: true)
        return container
    }
}
