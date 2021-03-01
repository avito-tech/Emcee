import Foundation

public final class NSLogLikeLogEntryTextFormatter: LogEntryTextFormatter {
    
    // 2018-03-29 19:05:01.994
    public static let logDateFormatter: DateFormatter = {
        let logFormatter = DateFormatter()
        logFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        logFormatter.timeZone = TimeZone.autoupdatingCurrent
        return logFormatter
    }()
    
    public init() {}
    
    public func format(logEntry: LogEntry) -> String {
        let timeStamp = NSLogLikeLogEntryTextFormatter.logDateFormatter.string(from: logEntry.timestamp)
        
        let filename = logEntry.file.lastPathComponent
        
        // [LEVEL] 2018-03-29 19:05:01.994 <file:line> <coordinate1> [<coordinate2> [...]]: <mesage>
        var result = "[\(logEntry.verbosity.stringCode)] \(timeStamp) \(filename):\(logEntry.line)"
        if !logEntry.coordinates.isEmpty {
            result += " " + logEntry.coordinates.joined(separator: " ")
        }
        result += ": " + logEntry.message
        return result
    }
}
