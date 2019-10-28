import Foundation

public final class FbSimCtlEventWithStringSubject: FbSimCtlEventCommonFields, Decodable, Hashable, CustomStringConvertible {
    public let type: FbSimCtlEventType
    public let name: FbSimCtlEventName
    public let timestamp: TimeInterval
    public let subject: String

    public init(
        type: FbSimCtlEventType,
        name: FbSimCtlEventName,
        timestamp: TimeInterval,
        subject: String
    ) {
        self.type = type
        self.name = name
        self.timestamp = timestamp
        self.subject = subject
    }

    private enum CodingKeys: String, CodingKey {
        case type = "event_type"
        case name = "event_name"
        case timestamp = "timestamp"
        case subject = "subject"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(type)
        hasher.combine(name)
        hasher.combine(timestamp)
        hasher.combine(subject)
    }

    public static func == (left: FbSimCtlEventWithStringSubject, right: FbSimCtlEventWithStringSubject) -> Bool {
        return left.type == right.type
            && left.name == right.name
            && left.timestamp == right.timestamp
            && left.subject == right.subject
    }

    public var description: String {
        return "\(FbSimCtlEventWithStringSubject.self) \(name) \(type) \(timestamp) \(subject)"
    }
}
