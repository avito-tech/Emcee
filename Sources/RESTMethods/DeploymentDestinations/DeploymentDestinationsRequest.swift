import Deployer
import Models
import RequestSender
import RESTInterfaces

public final class DeploymentDestinationsRequest: NetworkRequest {
    public typealias Response = DeploymentDestinationsResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.deploymentDestinations.pathWithLeadingSlash

    public let payload: VoidPayload? = nil
    public init() { }
}
