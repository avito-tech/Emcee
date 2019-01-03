import Extensions
import Foundation

public final class NSLogLikeLogEntryTextFormatter: LogEntryTextFormatter {
    
    // 2018-03-29 19:05:01.994+0300
    public static let logDateFormatter: DateFormatter = {
        let logFormatter = DateFormatter()
        logFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSSZZZ"
        logFormatter.timeZone = TimeZone.autoupdatingCurrent
        return logFormatter
    }()
    
    public init() {}
    
    public func format(logEntry: LogEntry) -> String {
        let processInfo = ProcessInfo.processInfo
        let timeStamp = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: logEntry.timestamp)
        
        var result = "[\(logEntry.verbosity.stringCode)] \(timeStamp) \(processInfo.processName)[\(processInfo.processIdentifier)]"
        
        if let subprocessInfo = logEntry.subprocessInfo {
            result += " \(subprocessInfo.subprocessName)[\(subprocessInfo.subprocessId)]"
        }
        
        result += ": "
        
        if logEntry.verbosity >= .debug {
            let filename = logEntry.file.description.lastPathComponent
            result += "\(filename):\(logEntry.line): "
        }
        
        result += logEntry.message
        
        return result
    }
}
