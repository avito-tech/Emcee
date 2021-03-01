import Foundation

public final class PidInfo: Equatable {
    public let pid: Int32
    public let name: String

    public init(pid: Int32, name: String) {
        self.pid = pid
        self.name = name
    }
    
    public static func ==(left: PidInfo, right: PidInfo) -> Bool {
        return left.pid == right.pid
            && left.name == right.name
    }
}

public final class LogEntry: Equatable {
    public let file: StaticString
    public let line: UInt
    public let message: String
    public let pidInfo: PidInfo?
    public let timestamp: Date
    public let verbosity: Verbosity

    public init(
        file: StaticString = #file,
        line: UInt = #line,
        message: String,
        pidInfo: PidInfo? = nil,
        timestamp: Date = Date(),
        verbosity: Verbosity
    ) {
        self.file = file
        self.line = line
        self.message = message
        self.pidInfo = pidInfo
        self.timestamp = timestamp
        self.verbosity = verbosity
    }
    
    public static func ==(left: LogEntry, right: LogEntry) -> Bool {
        return left.file.description == right.file.description
            && left.line == right.line
            && left.message == right.message
            && left.pidInfo == right.pidInfo
            && left.timestamp == right.timestamp
            && left.verbosity == right.verbosity
    }
}
