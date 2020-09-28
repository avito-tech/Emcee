import Foundation
import RESTInterfaces
import RequestSender

public final class JobDeleteRequest: NetworkRequest {
    public typealias Response = JobDeleteResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = JobDeleteRESTMethod().pathWithLeadingSlash

    public let payload: JobDeletePayload?
    public init(payload: JobDeletePayload) {
        self.payload = payload
    }
}
