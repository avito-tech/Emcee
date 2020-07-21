import Foundation

/// This logger handler will get all log entries. You must specify it prior any call to `Logger` methods,
/// otherwise the log entries will be lost.
public final class GlobalLoggerConfig {
    public static var loggerHandler: LoggerHandler = AggregatedLoggerHandler(handlers: [])
}
