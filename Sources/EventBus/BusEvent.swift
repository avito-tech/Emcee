import Foundation
import Models

public enum BusEvent: Codable {
    case runnerEvent(RunnerEvent)
    case tearDown
    
    enum CodingKeys: CodingKey {
        case eventType
        case testingResult
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
            let runnerEvent = try container.decode(RunnerEvent.self, forKey: .runnerEvent)
            self = .runnerEvent(runnerEvent)
        case .tearDown:
            self = .tearDown
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .runnerEvent(let runnerEvent):
            try container.encode(EventType.runnerEvent, forKey: .eventType)
            try container.encode(runnerEvent, forKey: .runnerEvent)
        case .tearDown:
            try container.encode(EventType.tearDown, forKey: .eventType)
        }
    }
}
