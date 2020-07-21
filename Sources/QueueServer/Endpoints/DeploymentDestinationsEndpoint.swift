import Deployer
import RequestSender
import RESTInterfaces
import RESTMethods
import RESTServer

public final class DeploymentDestinationsEndpoint: RESTEndpoint {
    public let path: RESTPath = RESTMethod.deploymentDestinations
    
    public let requestIndicatesActivity = false
    
    private let destinations: [DeploymentDestination]
    public init(destinations: [DeploymentDestination]) {
        self.destinations = destinations
    }
    
    public func handle(payload: VoidPayload) throws -> DeploymentDestinationsResponse {
        return .deploymentDestinations(destinations: destinations)
    }
}
