import RequestSender

public final class BucketResultRequest: NetworkRequest {
    public typealias Response = BucketResultAcceptResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.bucketResult.withLeadingSlash

    public let payload: BucketResultPayload?
    public init(payload: BucketResultPayload) {
        self.payload = payload
    }
}
