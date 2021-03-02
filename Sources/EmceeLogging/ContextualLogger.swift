import Foundation
import Logging
import QueueModels

public final class ContextualLogger {
    private let logger: Logging.Logger
    
    public enum ContextKeys: String {
        case subprocess
        case pid
        case name
        case workerProcess
        case workerId
    }
    
    private static let workerProcessMetadata: Logging.Logger.Metadata = [
        ContextKeys.pid.rawValue: .string("\(ProcessInfo.processInfo.processIdentifier)"),
        ContextKeys.name.rawValue: .string(ProcessInfo.processInfo.processName),
    ]
    
    public init<T>(_ type: T.Type) {
        logger = Logging.Logger(label: "\(T.self)")
    }
    
    public func log(
        _ verbosity: Verbosity,
        _ message: String,
        pidInfo: PidInfo? = nil,
        workerId: WorkerId? = nil,
        source: String? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        var metadata: Logging.Logger.Metadata = [:]
        
        metadata[ContextKeys.workerProcess.rawValue] = .dictionary(Self.workerProcessMetadata)
        
        if let pidInfo = pidInfo {
            metadata[ContextKeys.subprocess.rawValue] = [
                ContextKeys.name.rawValue: .string(pidInfo.name),
                ContextKeys.pid.rawValue: .string("\(pidInfo.pid)"),
            ]
        }
        
        if let workerId = workerId {
            metadata[ContextKeys.workerId.rawValue] = .stringConvertible(workerId)
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
