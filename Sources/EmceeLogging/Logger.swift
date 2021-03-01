import Foundation

public final class Logger {
    private init() {}
    
    public static func verboseDebug(
        _ message: String,
        _ pidInfo: PidInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.verboseDebug, message, pidInfo, file: file, line: line)
    }
    
    public static func debug(
        _ message: String,
        _ pidInfo: PidInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.debug, message, pidInfo, file: file, line: line)
    }
    
    public static func info(
        _ message: String,
        _ pidInfo: PidInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.info, message, pidInfo, file: file, line: line)
    }
    
    public static func warning(
        _ message: String,
        _ pidInfo: PidInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.warning, message, pidInfo, file: file, line: line)
    }
    
    public static func error(
        _ message: String,
        _ pidInfo: PidInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.error, message, pidInfo, file: file, line: line)
    }
    
    public static func always(
        _ message: String,
        _ pidInfo: PidInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line) 
    {
        log(.always, message, pidInfo, file: file, line: line)
    }
    
    public static func log(
        _ verbosity: Verbosity,
        _ message: String,
        _ pidInfo: PidInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        let logEntry = LogEntry(
            file: file,
            line: line,
            message: message,
            pidInfo: pidInfo,
            timestamp: Date(),
            verbosity: verbosity
        )
        log(logEntry)
    }
    
    public static func log(_ logEntry: LogEntry) {
        GlobalLoggerConfig.loggerHandler.handle(logEntry: logEntry)
    }
}
