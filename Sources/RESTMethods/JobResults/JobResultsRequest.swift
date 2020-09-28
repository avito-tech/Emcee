import RESTInterfaces
import RequestSender

public final class JobResultRequest: NetworkRequest {
    public typealias Response = JobResultsResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = JobResultsRESTMethod().pathWithLeadingSlash

    public let payload: JobResultsPayload?
    public init(payload: JobResultsPayload) {
        self.payload = payload
    }
}
