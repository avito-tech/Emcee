import Foundation
import Types

public struct MeasurementResult<T> {
    public let result: Either<T, Error>
    public let startTime: Date
    public let duration: TimeInterval
    
    public var endTime: Date {
        startTime.addingTimeInterval(duration)
    }
    
    public init(
        result: Either<T, Error>,
        startTime: Date,
        duration: TimeInterval
    ) {
        self.result = result
        self.startTime = startTime
        self.duration = duration
    }
    
    public init(
        result: Either<T, Error>,
        startTime: Date,
        endTime: Date
    ) {
        self.result = result
        self.startTime = startTime
        self.duration = endTime.timeIntervalSince(startTime)
    }
}
