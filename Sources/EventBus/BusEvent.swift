import Foundation
import Models

public enum BusEvent: Codable {
    case 
    case didObtainTestingResult(TestingResult)
    case tearDown
    
    enum CodingKeys: CodingKey {
        case eventType
        case testingResult
    }
    
    private enum EventType: String, Codable {
        case didObtainTestingResult
        case tearDown
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let eventType = try container.decode(EventType.self, forKey: .eventType)
        switch eventType {
        case .didObtainTestingResult:
            let testingResult = try container.decode(TestingResult.self, forKey: .testingResult)
            self = .didObtainTestingResult(testingResult)
        case .tearDown:
            self = .tearDown
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .didObtainTestingResult(testingResult):
            try container.encode(EventType.didObtainTestingResult, forKey: .eventType)
            try container.encode(testingResult, forKey: .testingResult)
        case .tearDown:
            try container.encode(EventType.tearDown, forKey: .eventType)
        }
    }
}
