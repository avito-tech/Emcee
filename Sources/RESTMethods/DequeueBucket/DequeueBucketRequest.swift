import RESTInterfaces
import RequestSender

public final class DequeueBucketRequest: NetworkRequest {
    public typealias Response = DequeueBucketResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.getBucket.pathWithLeadingSlash

    public let payload: DequeueBucketPayload?
    public init(payload: DequeueBucketPayload) {
        self.payload = payload
    }
}
