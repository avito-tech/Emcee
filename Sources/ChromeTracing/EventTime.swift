import Foundation

public final class EventTime: Encodable {
    public let microTime: TimeInterval

    public init(microTime: TimeInterval) {
        self.microTime = microTime
    }

    public static func seconds(_ seconds: TimeInterval) -> EventTime {
        return EventTime(microTime: seconds * 1000 * 1000)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(microTime)
    }
}
