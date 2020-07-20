import DistWorkerModels
import Foundation
import QueueModels

public enum WorkersToUtilizeResponse: Codable, Equatable {
    case workersToUtilize(workerIds: Set<WorkerId>)
    
    private enum CodingKeys: CodingKey {
        case caseId
        case workerIds
    }
    
    private enum CaseId: String, Codable {
        case workersToUtilize
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .workersToUtilize:
            self = .workersToUtilize(
                workerIds: try container.decode(Set<WorkerId>.self, forKey: .workerIds)
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .workersToUtilize(let workerIds):
            try container.encode(CaseId.workersToUtilize, forKey: .caseId)
            try container.encode(workerIds, forKey: .workerIds)
        }
    }
}
