import EmceeVersion
import Foundation
import Logging
import ProcessController
import QueueModels

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
    private let logger: Logging.Logger
    
    public enum ContextKeys: String {
        case subprocessId
        case subprocessName
        case processId
        case processName
        case workerId
        case emceeCommand
        case emceeVersion
        case persistentMetricsJobId
        case hostname
    }
    
    public static let noOp: ContextualLogger = ContextualLogger(
        logger: Logging.Logger(
            label: "no-op",
            factory: { _ in SwiftLogNoOpLogHandler() }
        ),
        addedMetadata: [:]
    )

    public init(logger: Logging.Logger, addedMetadata: [String: String]) {
        self.logger = logger
        self.addedMetadata = addedMetadata
    }
    
    private let addedMetadata: [String: String]
    
    func withMetadata(_ keyValues: [String: String]) -> ContextualLogger {
        var addedMetadata = self.addedMetadata
        addedMetadata.merge(keyValues) { _, new -> String in new }
        return ContextualLogger(logger: logger, addedMetadata: addedMetadata)
    }
    
    public func withMetadata(key: String, value: String) -> ContextualLogger {
        var addedMetadata = self.addedMetadata
        addedMetadata[key] = value
        return ContextualLogger(logger: logger, addedMetadata: addedMetadata)
    }
    
    public func withMetadata(key: ContextKeys, value: String) -> ContextualLogger {
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
        var metadata: Logging.Logger.Metadata = [:]
        
        for keyValue in addedMetadata {
            metadata[keyValue.key] = .string(keyValue.value)
        }
        
        if let subprocessPidInfo = subprocessPidInfo {
            metadata[ContextKeys.subprocessId.rawValue] = .string("\(subprocessPidInfo.pid)")
            metadata[ContextKeys.subprocessName.rawValue] = .string(subprocessPidInfo.name)
        }
        
        if let workerId = workerId {
            metadata[ContextKeys.workerId.rawValue] = .string(workerId.value)
        }
        
        if let persistentMetricsJobId = persistentMetricsJobId {
            metadata[ContextKeys.persistentMetricsJobId.rawValue] = .string(persistentMetricsJobId)
        }
        
        logger.log(
            level: verbosity.level,
            "\(message)",
            metadata: metadata,
            source: source,
            file: file,
            function: function,
            line: line
        )
    }
}
