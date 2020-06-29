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
        Logger.always("To fetch detailed verbose log:")
        Logger.always("$ scp \(NSUserName())@\(LocalHostDeterminer.currentHostAddress):\(detailedLogPath.absolutePath) /tmp/\(filename).log && open /tmp/\(filename).log")
    }
    
    public func tearDown(timeout: TimeInterval) {
        GlobalLoggerConfig.loggerHandler.tearDownLogging(timeout: timeout)
    }
    
    public func cleanUpLogs(olderThan date: Date) throws {
        let queue = DispatchQueue(label: "LoggingSetup.cleanupQueue", attributes: .concurrent)
        
        Logger.debug("Will clean up old log files")
        let logsEnumerator = fileSystem.contentEnumerator(forPath: try fileSystem.emceeLogsFolder(), style: .deep)
        try logsEnumerator.each { (path: AbsolutePath) in
            guard path.extension == logFileExtension else { return }
            let modificationDate = try fileSystem.properties(forFileAtPath: path).modificationDate()
            if modificationDate < date {
                queue.async { [fileSystem] in
                    do {
                        Logger.debug("Cleaning up log file: \(path)")
                        try fileSystem.delete(fileAtPath: path)
                    } catch {
                        Logger.error("Failed to remove old log file at \(path): \(error)")
                    }
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
    
    private func logsContainerFolder() throws -> AbsolutePath {
        try fileSystem.folderForStoringLogs(processName: ProcessInfo.processInfo.processName)
    }
}
