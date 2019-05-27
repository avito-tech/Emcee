import Ansi
import Foundation

public final class Logger {
    private init() {}
    
    public static func verboseDebug(
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.verboseDebug, message, subprocessInfo: subprocessInfo, file: file, line: line)
    }
    
    public static func debug(
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.debug, message, subprocessInfo: subprocessInfo, file: file, line: line)
    }
    
    public static func info(
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.info, message, subprocessInfo: subprocessInfo, file: file, line: line)
    }
    
    public static func warning(
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.warning, message, subprocessInfo: subprocessInfo, file: file, line: line)
    }
    
    public static func error(
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        log(.error, message, subprocessInfo: subprocessInfo, file: file, line: line)
    }
    
    public static func fatal(
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line) -> Never
    {
        log(.fatal, message, subprocessInfo: subprocessInfo, file: file, line: line)
        fatalError(message)
    }
    
    public static func always(
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        file: StaticString = #file,
        line: UInt = #line) 
    {
        log(.always, message, subprocessInfo: subprocessInfo, file: file, line: line)
    }
    
    public static func log(
        _ verbosity: Verbosity,
        _ message: String,
        subprocessInfo: SubprocessInfo? = nil,
        color: ConsoleColor? = nil,
        file: StaticString = #file,
        line: UInt = #line)
    {
        let logEntry = LogEntry(
            file: file,
            line: line,
            message: message,
            color: color,
            subprocessInfo: subprocessInfo,
            timestamp: Date(),
            verbosity: verbosity
        )
        log(logEntry)
    }
    
    public static func log(_ logEntry: LogEntry) {
        GlobalLoggerConfig.loggerHandler.handle(logEntry: logEntry)
    }
}
