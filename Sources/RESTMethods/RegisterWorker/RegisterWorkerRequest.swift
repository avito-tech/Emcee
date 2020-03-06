import RequestSender
import Models

public final class RegisterWorkerRequest: NetworkRequest {
    public typealias Response = RegisterWorkerResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.registerWorker.withLeadingSlash

    public let payload: RegisterWorkerPayload?
    public init(payload: RegisterWorkerPayload) {
        self.payload = payload
    }
}
