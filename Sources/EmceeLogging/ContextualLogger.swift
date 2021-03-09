import EmceeVersion
import Foundation
import Logging
import QueueModels

public final class ContextualLogger {
    private let logger: Logging.Logger
    
    public enum ContextKeys: String {
        case subprocessId
        case subprocessName
        case processId
        case processName
        case workerId
        case emceeVersion
        case persistentMetricsJobId
    }
    
    private static func createTypedLogger<T>(_ type: T.Type) -> Logging.Logger {
        Logging.Logger(label: "\(T.self)")
    }
    
    public convenience init<T>(_ type: T.Type) {
        self.init(logger: Self.createTypedLogger(type), addedMetadata: [:])
    }
    
    public convenience init(logger: Logging.Logger) {
        self.init(logger: logger, addedMetadata: [:])
    }
    
    public init(logger: Logging.Logger, addedMetadata: [String: String]) {
        self.logger = logger
        self.addedMetadata = addedMetadata
    }
    
    private let addedMetadata: [String: String]
    
    public func withMetadata(key: String, value: String) -> ContextualLogger {
        var addedMetadata = self.addedMetadata
        addedMetadata[key] = value
        return ContextualLogger(logger: logger, addedMetadata: addedMetadata)
    }
    
    public func withMetadata(key: ContextKeys, value: String) -> ContextualLogger {
        withMetadata(key: key.rawValue, value: value)
    }
    
    public func forType<T>(_ type: T.Type) -> ContextualLogger {
        ContextualLogger(logger: Self.createTypedLogger(type), addedMetadata: addedMetadata)
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

public extension ContextualLogger {
    func debug(
        _ message: String, subprocessPidInfo: PidInfo? = nil, workerId: WorkerId? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #file, function: String = #function, line: UInt = #line
    ) {
        log(.debug, message, subprocessPidInfo: subprocessPidInfo, workerId: workerId, persistentMetricsJobId: persistentMetricsJobId, source: source, file: file, function: function, line: line)
    }
    
    func error(
        _ message: String, subprocessPidInfo: PidInfo? = nil, workerId: WorkerId? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #file, function: String = #function, line: UInt = #line
    ) {
        log(.error, message, subprocessPidInfo: subprocessPidInfo, workerId: workerId, persistentMetricsJobId: persistentMetricsJobId, source: source, file: file, function: function, line: line)
    }
    
    func info(
        _ message: String, subprocessPidInfo: PidInfo? = nil, workerId: WorkerId? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #file, function: String = #function, line: UInt = #line
    ) {
        log(.info, message, subprocessPidInfo: subprocessPidInfo, workerId: workerId, persistentMetricsJobId: persistentMetricsJobId, source: source, file: file, function: function, line: line)
    }
}
