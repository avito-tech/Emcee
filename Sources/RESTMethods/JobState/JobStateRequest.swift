import Foundation
import RESTInterfaces
import RequestSender

public final class JobStateRequest: NetworkRequest {
    public typealias Response = JobStateResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = KickstartWorkerRESTMethod().pathWithLeadingSlash

    public let payload: JobStatePayload?
    public init(payload: JobStatePayload) {
        self.payload = payload
    }
}
