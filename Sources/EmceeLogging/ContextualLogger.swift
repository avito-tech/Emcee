import EmceeVersion
import Foundation
import Logging
import QueueModels

public final class ContextualLogger {
    private let logger: Logging.Logger
    
    public enum ContextKeys: String {
        case subprocessId
        case subprocessName
        case workerProcessId
        case workerProcessName
        case workerId
        case emceeVersion
        case persistentMetricsJobId
    }
    
    public convenience init<T>(_ type: T.Type) {
        self.init(logger: Logging.Logger(label: "\(T.self)"))
    }
    
    public init(logger: Logging.Logger) {
        self.logger = logger
    }
    
    public func log(
        _ verbosity: Verbosity,
        _ message: String,
        pidInfo: PidInfo? = nil,
        workerId: WorkerId? = nil,
        persistentMetricsJobId: String? = nil,
        source: String? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        var metadata: Logging.Logger.Metadata = [:]
        
        let workerProcessInfo = ProcessInfo.processInfo
        metadata[ContextKeys.workerProcessId.rawValue] = .string("\(workerProcessInfo.processIdentifier)")
        metadata[ContextKeys.workerProcessName.rawValue] = .string(workerProcessInfo.processName)
        metadata[ContextKeys.emceeVersion.rawValue] = .string(EmceeVersion.version.value)
        
        if let pidInfo = pidInfo {
            metadata[ContextKeys.subprocessId.rawValue] = .string("\(pidInfo.pid)")
            metadata[ContextKeys.subprocessName.rawValue] = .string(pidInfo.name)
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
