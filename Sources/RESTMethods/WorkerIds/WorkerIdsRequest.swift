import Deployer
import RequestSender
import RESTInterfaces

public final class WorkerIdsRequest: NetworkRequest {
    public typealias Response = WorkerIdsResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.workerIds.pathWithLeadingSlash

    public let payload: VoidPayload? = VoidPayload()
    public init() { }
}
