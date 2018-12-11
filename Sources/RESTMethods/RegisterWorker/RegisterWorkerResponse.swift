import Foundation
import Models

public enum RegisterWorkerResponse: Codable, Equatable {
    case workerRegisterSuccess(workerConfiguration: WorkerConfiguration)
    
    private enum CodingKeys: CodingKey {
        case caseId
        case workerConfiguration
    }
    
    private enum CaseId: String, Codable {
        case workerRegisterSuccess
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .workerRegisterSuccess:
            self = .workerRegisterSuccess(
                workerConfiguration: try container.decode(
                    WorkerConfiguration.self,
                    forKey: .workerConfiguration
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .workerRegisterSuccess(let workerConfiguration):
            try container.encode(CaseId.workerRegisterSuccess, forKey: .caseId)
            try container.encode(workerConfiguration, forKey: .workerConfiguration)
        }
    }
}
