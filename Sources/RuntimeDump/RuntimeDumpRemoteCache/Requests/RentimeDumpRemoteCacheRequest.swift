import RequestSender

class RentimeDumpRemoteCacheStoreRequest: NetworkRequest {
    typealias Response = EmptyData

    public let httpMethod: HTTPMethod
    public let pathWithLeadingSlash: String
    public let payload: RuntimeQueryResult?

    public init(
        httpMethod: HTTPMethod,
        pathWithLeadingSlash: String,
        payload: RuntimeQueryResult
    ) {
        self.httpMethod = httpMethod
        self.pathWithLeadingSlash = pathWithLeadingSlash
        self.payload = payload
    }
}
