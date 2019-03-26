import Foundation

public enum FbSimCtlEventType: String, Decodable {
    case started
    case discrete
    case ended
}

public enum FbSimCtlEventName: String, Decodable {
    case boot
    case log
    case listen
    case failure
    case create
    case delete
    case launch
    case state
}

public protocol FbSimCtlEventCommonFields {
    var type: FbSimCtlEventType { get }
    var name: FbSimCtlEventName { get }
}

public final class FbSimCtlEvent: FbSimCtlEventCommonFields, Decodable, Hashable, CustomStringConvertible {
    public let type: FbSimCtlEventType
    public let name: FbSimCtlEventName
    public let timestamp: TimeInterval
    
    public init(type: FbSimCtlEventType, name: FbSimCtlEventName, timestamp: TimeInterval) {
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
    
    public static func == (l: FbSimCtlEvent, r: FbSimCtlEvent) -> Bool {
        return l.type == r.type &&
        l.name == r.name &&
        l.timestamp == r.timestamp
    }
    
    public var description: String {
        return "\(name) \(type)"
    }
}

public final class FbSimCtlEventWithStringSubject: FbSimCtlEventCommonFields, Decodable, Hashable, CustomStringConvertible {
    public let type: FbSimCtlEventType
    public let name: FbSimCtlEventName
    public let timestamp: TimeInterval
    public let subject: String
    
    public init(type: FbSimCtlEventType, name: FbSimCtlEventName, timestamp: TimeInterval, subject: String) {
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
    
    public static func == (l: FbSimCtlEventWithStringSubject, r: FbSimCtlEventWithStringSubject) -> Bool {
        return l.type == r.type &&
            l.name == r.name &&
            l.timestamp == r.timestamp &&
            l.subject == r.subject
    }
    
    public var description: String {
        return "\(name) \(type): \(subject)"
    }
}
