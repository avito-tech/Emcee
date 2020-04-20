import RequestSender
import Models
import Deployer

public final class WorkersToUtilizeRequest: NetworkRequest {
    public typealias Response = WorkersToUtilizeResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.workersToUtilize.withLeadingSlash

    public let payload: [DeploymentDestination]?
    public init(deployments: [DeploymentDestination]) {
        self.payload = deployments
    }
}
