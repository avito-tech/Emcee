import Foundation

public enum BusEvent: Codable, Equatable {
    case appleRunnerEvent(AppleRunnerEvent)
    case tearDown
    
    enum CodingKeys: CodingKey {
        case eventType
        case runnerEvent
    }
    
    private enum EventType: String, Codable {
        case runnerEvent
        case tearDown
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(EventType.self, forKey: .eventType)
        switch eventType {
        case .runnerEvent:
            let runnerEvent = try container.decode(AppleRunnerEvent.self, forKey: .runnerEvent)
            self = .appleRunnerEvent(runnerEvent)
        case .tearDown:
            self = .tearDown
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .appleRunnerEvent(let runnerEvent):
            try container.encode(EventType.runnerEvent, forKey: .eventType)
            try container.encode(runnerEvent, forKey: .runnerEvent)
        case .tearDown:
            try container.encode(EventType.tearDown, forKey: .eventType)
        }
    }
}
