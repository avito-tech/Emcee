import DateProvider
import Dispatch
import FileSystem
import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import PathLib
import Sentry
import TemporaryStuff

public final class LoggingSetup {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let logFileExtension = "log"
    private let logFilePrefix = "pid_"
    private let logFilesCleanUpRegularity: TimeInterval = 10800
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem
    ) {
        self.dateProvider = dateProvider
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
    
    public static func tearDown(timeout: TimeInterval) {
        GlobalLoggerConfig.loggerHandler.tearDownLogging(timeout: timeout)
    }
    
    public func cleanUpLogs(
        olderThan date: Date,
        queue: OperationQueue,
        completion: @escaping (Error?) -> ()
    ) throws {
        let emceeLogsCleanUpMarkerFileProperties = fileSystem.properties(
            forFileAtPath: try fileSystem.emceeLogsCleanUpMarkerFile()
        )
        guard dateProvider.currentDate().timeIntervalSince(
            try emceeLogsCleanUpMarkerFileProperties.modificationDate()
        ) > logFilesCleanUpRegularity else {
            return Logger.debug("Skipping log clean up since last clean up happened recently")
        }
        
        Logger.info("Cleaning up old log files")
        try emceeLogsCleanUpMarkerFileProperties.touch()
        
        let logsEnumerator = fileSystem.contentEnumerator(forPath: try fileSystem.emceeLogsFolder(), style: .deep)

        queue.addOperation {
            do {
                try logsEnumerator.each { (path: AbsolutePath) in
                    guard path.extension == self.logFileExtension else { return }
                    let modificationDate = try self.fileSystem.properties(forFileAtPath: path).modificationDate()
                    if modificationDate < date {
                        do {
                            try self.fileSystem.delete(fileAtPath: path)
                        } catch {
                            Logger.error("Failed to remove old log file at \(path): \(error)")
                        }
                    }
                }
                completion(nil)
            } catch {
                completion(error)
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
