import Ansi
import Dispatch
import FileSystem
import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import Models
import PathLib
import Sentry
import TemporaryStuff

public final class LoggingSetup {
    private let fileSystem: FileSystem
    private let logFilePrefix = "pid_"
    private let logFileExtension = "log"
    
    public init(
        fileSystem: FileSystem
    ) {
        self.fileSystem = fileSystem
    }
    
    public func setupLogging(stderrVerbosity: Verbosity) throws {
        let filename = logFilePrefix + String(ProcessInfo.processInfo.processIdentifier)
        let detailedLogPath = try TemporaryFile(
            containerPath: try logsContainerFolder(),
            prefix: filename,
            suffix: "." + logFileExtension,
            deleteOnDealloc: false
        )
        
        let aggregatedHandler = AggregatedLoggerHandler(
            handlers: createLoggerHandlers(
                stderrVerbosity: stderrVerbosity,
                detaildLogFileHandle: detailedLogPath.fileHandleForWriting
            )
        )
        GlobalLoggerConfig.loggerHandler = aggregatedHandler
        Logger.always("Logging verbosity level is set to \(stderrVerbosity.stringCode)")
        Logger.always("To fetch detailed verbose log:")
        Logger.always("$ scp \(NSUserName())@\(LocalHostDeterminer.currentHostAddress):\(detailedLogPath.absolutePath) /tmp/\(filename).log && open /tmp/\(filename).log")
    }
    
    public func tearDown(timeout: TimeInterval) {
        GlobalLoggerConfig.loggerHandler.tearDownLogging(timeout: timeout)
    }
    
    public func cleanUpLogs(olderThan date: Date) throws {
        Logger.debug("Will clean up old log files")
        let emceeLogsFolder = try self.emceeLogsFolder()
        let logsEnumerator = fileSystem.contentEnumerator(forPath: emceeLogsFolder)
        try logsEnumerator.each { (path: AbsolutePath) in
            guard path.lastComponent.hasPrefix(logFilePrefix) && path.extension == logFileExtension else { return }
            let modificationDate = try fileSystem.properties(forFileAtPath: path).modificationDate()
            if modificationDate < date {
                do {
                    Logger.debug("Cleaning up log file: \(path)")
                    try fileSystem.delete(fileAtPath: path)
                } catch {
                    Logger.error("Failed to remove old log file at \(path): \(error)")
                }
            }
        }
    }
    
    private func createLoggerHandlers(
        stderrVerbosity: Verbosity,
        detaildLogFileHandle: FileHandle
    ) -> [LoggerHandler] {
        return [
            createStderrInfoLoggerHandler(verbosity: stderrVerbosity),
            createDetailedLoggerHandler(fileHandle: detaildLogFileHandle)
        ]
    }
    
    private func createStderrInfoLoggerHandler(verbosity: Verbosity) -> LoggerHandler {
        return FileHandleLoggerHandler(
            fileHandle: FileHandle.standardError,
            verbosity: verbosity,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            supportsAnsiColors: true,
            fileHandleShouldBeClosed: false
        )
    }
    
    private func createDetailedLoggerHandler(fileHandle: FileHandle) -> LoggerHandler {
        return FileHandleLoggerHandler(
            fileHandle: fileHandle,
            verbosity: Verbosity.verboseDebug,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            supportsAnsiColors: false,
            fileHandleShouldBeClosed: true
        )
    }
    
    private func emceeLogsFolder() throws -> AbsolutePath {
        let libraryPath = try fileSystem.commonlyUsedPathsProvider.library(inDomain: .user, create: false)
        return libraryPath.appending(components: ["Logs", "ru.avito.emcee.logs"])
    }
    
    private func logsContainerFolder() throws -> AbsolutePath {
        let emceeLogsFolder = try self.emceeLogsFolder()
        try fileSystem.createDirectory(atPath: emceeLogsFolder, withIntermediateDirectories: true)
        
        let container = emceeLogsFolder.appending(component: ProcessInfo.processInfo.processName)
        try fileSystem.createDirectory(atPath: container, withIntermediateDirectories: true)
        
        return container
    }
}
