import Foundation

public struct LogEntry: Equatable, Codable {
    public let file: String
    public let line: UInt
    public private(set) var coordinates: [LogEntryCoordinate]
    public let message: String
    public let timestamp: Date
    public let verbosity: Verbosity

    public init(
        file: String,
        line: UInt,
        coordinates: [LogEntryCoordinate],
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
    
    public func with(appendedCoordinate: LogEntryCoordinate) -> Self {
        var newCoordinates = coordinates
        newCoordinates.append(appendedCoordinate)
        
        return with(coordinates: newCoordinates)
    }
    
    public func with(coordinates: [LogEntryCoordinate]) -> Self {
        var result = self
        result.coordinates = coordinates
        return result
    }
    
    public func coordinate(name: String) -> LogEntryCoordinate? {
        coordinates.first { $0.name == name }
    }
}
