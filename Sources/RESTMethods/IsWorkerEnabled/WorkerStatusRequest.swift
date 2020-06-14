import Models
import RESTInterfaces
import RequestSender

public final class WorkerStatusRequest: NetworkRequest {
    public typealias Response = WorkerStatusResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.workerStatus.pathWithLeadingSlash

    public let payload: WorkerStatusPayload?
    public init(payload: WorkerStatusPayload) {
        self.payload = payload
    }
}
