import RequestSender
import Models

public final class DisableWorkerRequest: NetworkRequest {
    public typealias Response = WorkerDisabledResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.disableWorker.withLeadingSlash

    public let payload: DisableWorkerPayload?
    public init(payload: DisableWorkerPayload) {
        self.payload = payload
    }
}
