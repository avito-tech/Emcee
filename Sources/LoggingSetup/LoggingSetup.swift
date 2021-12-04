import DateProvider
import Dispatch
import EmceeLogging
import FileSystem
import Foundation
import Kibana
import LocalHostDeterminer
import Logging
import Metrics
import MetricsExtensions
import PathLib
import Tmp

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
    
    public func setupLogging(stderrVerbosity: Verbosity) throws -> ContextualLogger {
        let filename = logFilePrefix + String(ProcessInfo.processInfo.processIdentifier)
        let detailedLogPath = try TemporaryFile(
            containerPath: try logsContainerFolder(),
            prefix: filename,
            suffix: "." + logFileExtension,
            deleteOnDealloc: false
        )
        
        GlobalLoggerConfig.loggerHandler.append(handler: createStderrInfoLoggerHandler(verbosity: stderrVerbosity))
        GlobalLoggerConfig.loggerHandler.append(handler: createDetailedLoggerHandler(fileHandle: detailedLogPath.fileHandleForWriting))
        
        LoggingSystem.bootstrap { _ in GlobalLoggerConfig.loggerHandler }
        
        let logger = ContextualLogger(logger: Logger(label: "emcee"), addedMetadata: [:])
        
        logger.info("To fetch detailed verbose log:")
        logger.info("$ scp \(NSUserName())@\(LocalHostDeterminer.currentHostAddress):\(detailedLogPath.absolutePath) /tmp/\(filename).log && open /tmp/\(filename).log")
        
        return logger
    }
    
    public func set(kibanaConfiguration: KibanaConfiguration) throws {
        let handler = KibanaLoggerHandler(
            kibanaClient: try HttpKibanaClient(
                dateProvider: dateProvider,
                endpoints: try kibanaConfiguration.endpoints.map { try KibanaHttpEndpoint.from(url: $0) },
                indexPattern: kibanaConfiguration.indexPattern,
                urlSession: .shared
            )
        )
        GlobalLoggerConfig.loggerHandler.append(handler: handler)
    }
    
    public func childProcessLogsContainerProvider() throws -> ChildProcessLogsContainerProvider {
        return ChildProcessLogsContainerProviderImpl(
            fileSystem: fileSystem,
            mainContainerPath: try logsContainerFolder()
        )
    }
    
    public static func tearDown(timeout: TimeInterval) {
        GlobalLoggerConfig.loggerHandler.tearDownLogging(timeout: timeout)
    }
    
    public func cleanUpLogs(
        logger: ContextualLogger,
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
            logger.debug("Skipping log clean up since last clean up happened recently")
            return
        }
        
        logger.info("Cleaning up old log files")
        try emceeLogsCleanUpMarkerFileProperties.touch()
        
        let logsEnumerator = fileSystem.contentEnumerator(forPath: try fileSystem.emceeLogsFolder(), style: .deep)

        queue.addOperation {
            do {
                try logsEnumerator.each { (path: AbsolutePath) in
                    guard path.extension == self.logFileExtension else { return }
                    let modificationDate = try self.fileSystem.properties(forFileAtPath: path).modificationDate()
                    if modificationDate < date {
                        do {
                            try self.fileSystem.delete(path: path)
                        } catch {
                            logger.error("Failed to remove old log file at \(path): \(error)")
                        }
                    }
                }
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    private func createStderrInfoLoggerHandler(verbosity: Verbosity) -> LoggerHandler {
        return FileHandleLoggerHandler(
            dateProvider: dateProvider,
            fileHandle: FileHandle.standardError,
            verbosity: verbosity,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            fileHandleShouldBeClosed: false,
            skipMetadataFlag: .skipStdOutput
        )
    }
    
    private func createDetailedLoggerHandler(fileHandle: FileHandle) -> LoggerHandler {
        return FileHandleLoggerHandler(
            dateProvider: dateProvider,
            fileHandle: fileHandle,
            verbosity: Verbosity.verboseDebug,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            fileHandleShouldBeClosed: true,
            skipMetadataFlag: .skipFileOutput
        )
    }
    
    private func logsContainerFolder() throws -> AbsolutePath {
        try fileSystem.folderForStoringLogs(processName: ProcessInfo.processInfo.processName)
    }
}
