import DateProvider
import Dispatch
import FileSystem
import EmceeLoggingModels
import Foundation
import Kibana
import MetricsRecording
import MetricsExtensions
import PathLib
import Tmp

public final class LoggingSetup {
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let logFileExtension = "log"
    private let logFilePrefix = "pid_"
    private let logFilesCleanUpRegularity: TimeInterval = 10800
    
    private let aggregatedLoggerHandler: AggregatedLoggerHandler
    
    public let rootLoggerHandler: LoggerHandler
    
    public init(
        dateProvider: DateProvider,
        fileSystem: FileSystem
    ) {
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.aggregatedLoggerHandler = AggregatedLoggerHandler(handlers: [])
        self.rootLoggerHandler = self.aggregatedLoggerHandler
    }
    
    public func setupLogging(
        stderrVerbosity: Verbosity,
        detailedLogVerbosity: Verbosity
    ) throws -> ContextualLogger {
        let filename = logFilePrefix + String(ProcessInfo.processInfo.processIdentifier)
        let detailedLogPath = try TemporaryFile(
            containerPath: try logsContainerFolder(),
            prefix: filename,
            suffix: "." + logFileExtension,
            deleteOnDealloc: false
        )
        
        add(
            loggerHandler: createStderrInfoLoggerHandler(
                verbosity: stderrVerbosity
            )
        )
        add(
            loggerHandler: createDetailedLoggerHandler(
                fileHandle: detailedLogPath.fileHandleForWriting,
                verbosity: detailedLogVerbosity
            )
        )
        
        let logger = ContextualLogger(
            dateProvider: dateProvider,
            loggerHandler: rootLoggerHandler,
            metadata: [:]
        )
        
        logger.info("Verbose logs available at: \(detailedLogPath.absolutePath)")
        
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
        add(loggerHandler: handler)
    }
    
    public func childProcessLogsContainerProvider() throws -> ChildProcessLogsContainerProvider {
        return ChildProcessLogsContainerProviderImpl(
            fileSystem: fileSystem,
            mainContainerPath: try logsContainerFolder()
        )
    }
    
    public func add(loggerHandler: LoggerHandler) {
        aggregatedLoggerHandler.append(handler: loggerHandler)
    }
    
    public func tearDown(timeout: TimeInterval) {
        aggregatedLoggerHandler.tearDownLogging(timeout: timeout)
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
            logger.trace("Skipping log clean up since last clean up happened recently")
            return
        }
        
        logger.trace("Cleaning up old log files")
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
    
    private func createDetailedLoggerHandler(
        fileHandle: FileHandle,
        verbosity: Verbosity
    ) -> LoggerHandler {
        return FileHandleLoggerHandler(
            dateProvider: dateProvider,
            fileHandle: fileHandle,
            verbosity: verbosity,
            logEntryTextFormatter: NSLogLikeLogEntryTextFormatter(),
            fileHandleShouldBeClosed: true,
            skipMetadataFlag: .skipFileOutput
        )
    }
    
    private func logsContainerFolder() throws -> AbsolutePath {
        try fileSystem.folderForStoringLogs(processName: ProcessInfo.processInfo.processName)
    }
}
