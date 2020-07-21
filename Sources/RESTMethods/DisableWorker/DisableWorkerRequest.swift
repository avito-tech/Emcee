import RESTInterfaces
import RequestSender

public final class DisableWorkerRequest: NetworkRequest {
    public typealias Response = WorkerDisabledResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.disableWorker.pathWithLeadingSlash

    public let payload: DisableWorkerPayload?
    public init(payload: DisableWorkerPayload) {
        self.payload = payload
    }
}
