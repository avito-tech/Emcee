import Foundation

public final class FbSimCtlEvent: FbSimCtlEventCommonFields, Decodable, Hashable, CustomStringConvertible {
    public let type: FbSimCtlEventType
    public let name: FbSimCtlEventName
    public let timestamp: TimeInterval

    public init(
        type: FbSimCtlEventType,
        name: FbSimCtlEventName,
        timestamp: TimeInterval
    ) {
        self.type = type
        self.name = name
        self.timestamp = timestamp
    }

    private enum CodingKeys: String, CodingKey {
        case type = "event_type"
        case name = "event_name"
        case timestamp = "timestamp"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
        hasher.combine(timestamp)
    }

    public static func == (left: FbSimCtlEvent, right: FbSimCtlEvent) -> Bool {
        return left.type == right.type
            && left.name == right.name
            && left.timestamp == right.timestamp
    }

    public var description: String {
        return "\(FbSimCtlEvent.self) \(name) \(type) \(timestamp)"
    }
}
