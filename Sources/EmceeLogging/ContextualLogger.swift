import DateProvider
import EmceeLoggingModels
import Foundation
import ProcessController
import QueueModels
import EmceeLoggingModels

/// # Philosophy behind a contextual logging system
/// Each layer of a software might want to log different information on top of other information added by layers on top.
/// Example:
///
/// * `main` entrypoint might put some metadata to a logger: pid, process name
/// * `command` being executed might add a command name, its arguments, probably user input
/// * `process executor` which is being used by a `command` may add `subprocessId` and `subprocessName` to loggable messages.
///
/// In order to achieve this, `main` may create its instance of `ContextualLogger` and pass it down to the objects
/// `command` may get the instance from `main`, and obtain its own instance by adding metadata. `ContextualLogger` here works like a factory.
/// When executing subprocess, `command` will pass its `ContextualLogger` to `process executor`.
/// `process executor` will again append its own metadata and use new instance to log its stuff.
/// This way metadata can be derived between layers of software, extending it where needed, and still allowing layers to log data with its set of metadata without being affected by other layers.
public final class ContextualLogger {
    private let dateProvider: DateProvider
    private let loggerHandler: LoggerHandler
    private let metadata: [String: String?]
    
    public enum ContextKeys: String, CaseIterable {
        /// Id of a subprocess started by Emcee process
        case subprocessId
        
        /// Name of a subprocess started by Emcee process
        case subprocessName
        
        /// Emcee process id
        case processId
        
        /// Emcee process name
        case processName
        
        /// Worker id
        case workerId
        
        /// Command being executed by Emcee process, e.g. `runTests`
        case emceeCommand
        
        /// Emcee version
        case emceeVersion
        
        /// Id (or type) of a job which is persistent across jobs, e.g. `E2eTests`
        case persistentMetricsJobId
        
        /// Hostname where Emcee process is being executed
        case hostname
        
        /// If subprocess is started via `xcrun`, this key contains a name of a launched tool, e.g. `simctl`
        case xcrunToolName
        
        public static func stringSetForAllRawValues() -> Set<String> {
            Set(allCases.map { $0.rawValue })
        }
    }
    
    public static let noOp: ContextualLogger = ContextualLogger(
        dateProvider: SystemDateProvider(),
        loggerHandler: AggregatedLoggerHandler(handlers: []),
        metadata: [:]
    )

    public init(
        dateProvider: DateProvider,
        loggerHandler: LoggerHandler,
        metadata: [String: String?]
    ) {
        self.dateProvider = dateProvider
        self.loggerHandler = loggerHandler
        self.metadata = metadata
    }
    
    public func withMetadata(_ keyValues: [String: String?]) -> ContextualLogger {
        var metadata = self.metadata
        metadata.merge(keyValues) { _, new -> String? in new }
        return ContextualLogger(dateProvider: dateProvider, loggerHandler: loggerHandler, metadata: metadata)
    }
    
    public func withMetadata(key: String, value: String?) -> ContextualLogger {
        var metadata = self.metadata
        metadata[key] = value
        return ContextualLogger(dateProvider: dateProvider, loggerHandler: loggerHandler, metadata: metadata)
    }
    
    public func withMetadata(_ coordinate: LogEntryCoordinate) -> ContextualLogger {
        var metadata = self.metadata
        metadata[coordinate.name] = coordinate.value
        return ContextualLogger(dateProvider: dateProvider, loggerHandler: loggerHandler, metadata: metadata)
    }
    
    public func withMetadata(key: ContextKeys, value: String?) -> ContextualLogger {
        withMetadata(key: key.rawValue, value: value)
    }
    
    public func log(
        _ verbosity: Verbosity,
        _ message: String,
        subprocessPidInfo: PidInfo?,
        workerId: WorkerId?,
        persistentMetricsJobId: String?,
        source: String?,
        file: String,
        function: String,
        line: UInt
    ) {
        var flattenedMetadata = self.metadata
        
        if let subprocessPidInfo = subprocessPidInfo {
            flattenedMetadata[ContextKeys.subprocessId.rawValue] = "\(subprocessPidInfo.pid)"
            flattenedMetadata[ContextKeys.subprocessName.rawValue] = "\(subprocessPidInfo.name)"
        }
        
        if let workerId = workerId {
            flattenedMetadata[ContextKeys.workerId.rawValue] = workerId.value
        }
        
        if let persistentMetricsJobId = persistentMetricsJobId {
            flattenedMetadata[ContextKeys.persistentMetricsJobId.rawValue] = persistentMetricsJobId
        }
        
        let coordinates = flattenedMetadata.map { (key: String, value: String?) in
            LogEntryCoordinate(name: key, value: value)
        }
        
        let logEntry = LogEntry(
            file: file,
            line: line,
            coordinates: coordinates,
            message: message,
            timestamp: dateProvider.currentDate(),
            verbosity: verbosity
        )
        
        loggerHandler.handle(logEntry: logEntry)
    }
}
