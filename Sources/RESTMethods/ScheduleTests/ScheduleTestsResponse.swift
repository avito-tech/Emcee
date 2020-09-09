import Foundation
import QueueModels

public enum ScheduleTestsResponse: Codable, Equatable {
    case scheduledTests
    
    enum CodingKeys: CodingKey {
        case responseType
    }
    
    private enum CaseId: String, Codable {
        case scheduledTests
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .scheduledTests:
            try container.encode(CaseId.scheduledTests, forKey: .responseType)
        }
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let responseType = try container.decode(CaseId.self, forKey: .responseType)
        switch responseType {
        case .scheduledTests:
            self = .scheduledTests
        }
    }
}
