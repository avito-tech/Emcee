import Foundation

public struct PidInfo: Equatable {
    public let pid: Int32
    public let name: String

    public init(pid: Int32, name: String) {
        self.pid = pid
        self.name = name
    }
}

public struct LogEntry: Equatable {
    public let file: String
    public let line: UInt
    public let coordinates: [String]
    public let message: String
    public let timestamp: Date
    public let verbosity: Verbosity

    public init(
        file: String,
        line: UInt,
        coordinates: [String],
        message: String,
        timestamp: Date,
        verbosity: Verbosity
    ) {
        self.file = file
        self.line = line
        self.coordinates = coordinates
        self.message = message
        self.timestamp = timestamp
        self.verbosity = verbosity
    }
}
