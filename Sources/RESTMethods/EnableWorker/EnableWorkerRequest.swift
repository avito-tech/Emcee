import RESTInterfaces
import RequestSender

public final class EnableWorkerRequest: NetworkRequest {
    public typealias Response = WorkerEnabledResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.enableWorker.pathWithLeadingSlash

    public let payload: EnableWorkerPayload?
    public init(payload: EnableWorkerPayload) {
        self.payload = payload
    }
}
