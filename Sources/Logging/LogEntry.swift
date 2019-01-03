import Ansi
import Foundation

public final class SubprocessInfo: Equatable {
    public let subprocessId: Int32
    public let subprocessName: String

    public init(subprocessId: Int32, subprocessName: String) {
        self.subprocessId = subprocessId
        self.subprocessName = subprocessName
    }
    
    public static func ==(left: SubprocessInfo, right: SubprocessInfo) -> Bool {
        return left.subprocessId == right.subprocessId
            && left.subprocessName == right.subprocessName 
    }
}

public final class LogEntry: Equatable {
    public let file: StaticString
    public let line: UInt
    public let message: String
    public let color: ConsoleColor?
    public let subprocessInfo: SubprocessInfo?
    public let timestamp: Date
    public let verbosity: Verbosity

    public init(
        file: StaticString = #file,
        line: UInt = #line,
        message: String,
        color: ConsoleColor? = nil,
        subprocessInfo: SubprocessInfo? = nil,
        timestamp: Date = Date(),
        verbosity: Verbosity)
    {
        self.file = file
        self.line = line
        self.message = message
        self.color = color
        self.subprocessInfo = subprocessInfo
        self.timestamp = timestamp
        self.verbosity = verbosity
    }
    
    public static func ==(left: LogEntry, right: LogEntry) -> Bool {
        return left.file.description == right.file.description
            && left.line == right.line
            && left.message == right.message
            && left.color == right.color
            && left.subprocessInfo == right.subprocessInfo
            && left.timestamp == right.timestamp
            && left.verbosity == right.verbosity
    }
}
