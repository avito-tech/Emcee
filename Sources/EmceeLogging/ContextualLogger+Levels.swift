import Foundation
import QueueModels

public extension ContextualLogger {
    func debug(
        _ message: String, subprocessPidInfo: PidInfo? = nil, workerId: WorkerId? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #file, function: String = #function, line: UInt = #line
    ) {
        log(.debug, message, subprocessPidInfo: subprocessPidInfo, workerId: workerId, persistentMetricsJobId: persistentMetricsJobId, source: source, file: file, function: function, line: line)
    }
    
    func trace(
        _ message: String, subprocessPidInfo: PidInfo? = nil, workerId: WorkerId? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #file, function: String = #function, line: UInt = #line
    ) {
        log(.trace, message, subprocessPidInfo: subprocessPidInfo, workerId: workerId, persistentMetricsJobId: persistentMetricsJobId, source: source, file: file, function: function, line: line)
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
    
    func warning(
        _ message: String, subprocessPidInfo: PidInfo? = nil, workerId: WorkerId? = nil, persistentMetricsJobId: String? = nil, source: String? = nil, file: String = #file, function: String = #function, line: UInt = #line
    ) {
        log(.warning, message, subprocessPidInfo: subprocessPidInfo, workerId: workerId, persistentMetricsJobId: persistentMetricsJobId, source: source, file: file, function: function, line: line)
    }
    
    func withMetadata(key: ContextKeys, value: String?) -> ContextualLogger {
        withMetadata(key: key.rawValue, value: value)
    }
    
    func withMetadata(key: String, value: String?) -> ContextualLogger {
        if let value = value {
            return withMetadata(key: key, value: value)
        }
        return self
    }
    
    var skippingStdOutput: ContextualLogger {
        withMetadata(key: FileHandleLoggerHandler.SkipMetadataFlag.skipStdOutput.rawValue, value: "true")
    }
    
    var skippingKibana: ContextualLogger {
        withMetadata(key: KibanaLoggerHandler.skipMetadataFlag, value: "true")
    }
}
