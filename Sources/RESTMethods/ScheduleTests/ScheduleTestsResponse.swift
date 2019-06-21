import Foundation
import Models

public enum ScheduleTestsResponse: Codable, Equatable {
    case scheduledTests(requestId: RequestId)
    
    enum CodingKeys: CodingKey {
        case responseType
        case requestId
    }
    
    private enum CaseId: String, Codable {
        case scheduledTests
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .scheduledTests(let requestId):
            try container.encode(CaseId.scheduledTests, forKey: .responseType)
            try container.encode(requestId, forKey: .requestId)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let responseType = try container.decode(CaseId.self, forKey: .responseType)
        switch responseType {
        case .scheduledTests:
            self = .scheduledTests(requestId: try container.decode(RequestId.self, forKey: .requestId))
        }
    }
}
