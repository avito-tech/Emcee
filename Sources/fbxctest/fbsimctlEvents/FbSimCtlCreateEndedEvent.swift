import Foundation
import Models
import SimulatorPoolModels

public final class FbSimCtlCreateEndedEvent: FbSimCtlEventCommonFields, Decodable, Hashable, CustomStringConvertible {
    public let name: FbSimCtlEventName = .create
    public let type: FbSimCtlEventType = .ended
    public let timestamp: TimeInterval
    public let subject: Subject

    public struct Subject: Decodable, Hashable, CustomStringConvertible {
        public let name: String     // iPhone SE
        public let arch: String     // x86_64
        public let os: String       // iOS 10.3
        public let model: String    // iPhone SE
        public let udid: UDID       // 046FB37A-7CE4-4CF4-BB6A-93FB91CD85A6

        public init(
            name: String,
            arch: String,
            os: String,
            model: String,
            udid: UDID
        ) {
            self.name = name
            self.arch = arch
            self.os = os
            self.model = model
            self.udid = udid
        }
        public var description: String {
            return "\(name) \(arch) \(os) \(model) \(udid)"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case type = "event_type"
        case name = "event_name"
        case timestamp = "timestamp"
        case subject = "subject"
    }

    public init(
        timestamp: TimeInterval,
        subject: Subject
    ) {
        self.timestamp = timestamp
        self.subject = subject
    }

    public var description: String {
        return "\(FbSimCtlCreateEndedEvent.self) \(name) \(type) \(timestamp) \(subject)"
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(name)
        hasher.combine(type)
        hasher.combine(timestamp)
        hasher.combine(subject)
    }

    public static func == (left: FbSimCtlCreateEndedEvent, right: FbSimCtlCreateEndedEvent) -> Bool {
        return left.name == right.name
            && left.type == right.type
            && left.timestamp == right.timestamp
            && left.subject == right.subject
    }
}
