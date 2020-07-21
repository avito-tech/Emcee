import Deployer
import Foundation

public enum DeploymentDestinationsResponse: Codable, Equatable {
    case deploymentDestinations(destinations: [DeploymentDestination])
    
    private enum CodingKeys: CodingKey {
        case caseId
        case destinations
    }
    
    private enum CaseId: String, Codable {
        case deploymentDestinations
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let caseId = try container.decode(CaseId.self, forKey: .caseId)
        switch caseId {
        case .deploymentDestinations:
            self = .deploymentDestinations(
                destinations: try container.decode([DeploymentDestination].self, forKey: .destinations)
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .deploymentDestinations(let destinations):
            try container.encode(CaseId.deploymentDestinations, forKey: .caseId)
            try container.encode(destinations, forKey: .destinations)
        }
    }
}
