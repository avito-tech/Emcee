import Deployer
import Models
import RequestSender
import RESTInterfaces

public final class WorkersToUtilizeRequest: NetworkRequest {
    public typealias Response = WorkersToUtilizeResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.workersToUtilize.pathWithLeadingSlash

    public let payload: [DeploymentDestination]?
    public init(deployments: [DeploymentDestination]) {
        self.payload = deployments
    }
}
