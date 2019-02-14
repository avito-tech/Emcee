import Ansi
import Basic
import Dispatch
import Foundation
import LocalHostDeterminer
import Logging
import Sentry
import Version

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
        
        let aggregatedHandler = AggregatedLoggerHandler(
            handlers: createLoggerHandlers(
                stderrVerbosity: stderrVerbosity,
                detaildLogFileHandle: detailedLogPath.fileHandle
            )
        )
        GlobalLoggerConfig.loggerHandler = aggregatedHandler
        Logger.always("Logging verbosity level is set to \(stderrVerbosity.stringCode)")
        Logger.always("To fetch detailed verbose log:")
        Logger.always("$ scp \(LocalHostDeterminer.currentHostAddress):\(detailedLogPath.path.asString) /tmp/\(filename).log")
        
        do {
            GlobalLoggerConfig.loggerHandler = aggregatedHandler.byAdding(
                handler: try createSentryLoggerHandler(verbosity: .warning)
            )
        } catch {
            Logger.warning("Error setting up sentry logger: \(error)")
        }
    }
    
    public static func tearDownLogging() {
        GlobalLoggerConfig.loggerHandler.tearDownLogging()
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
    
    private static func createSentryLoggerHandler(verbosity: Verbosity) throws -> LoggerHandler {
        let dsn = try DSN.create(dsnString: try EnvironmentDefinedDsnExtractor.dsnStringValue())
        let binaryVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
        return SentryLoggerHandler(
            dsn: dsn,
            hostname: LocalHostDeterminer.currentHostAddress,
            release: try binaryVersionProvider.version().stringValue,
            sentryEventDateFormatter: SentryDateFormatterFactory.createDateFormatter(),
            urlSession: URLSession.shared,
            verbosity: verbosity
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
