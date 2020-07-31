import RESTInterfaces
import RequestSender

public final class KickstartWorkerRequest: NetworkRequest {
    public typealias Response = KickstartWorkerResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = KickstartWorkerRESTMethod().pathWithLeadingSlash

    public let payload: KickstartWorkerPayload?
    public init(payload: KickstartWorkerPayload) {
        self.payload = payload
    }
}
