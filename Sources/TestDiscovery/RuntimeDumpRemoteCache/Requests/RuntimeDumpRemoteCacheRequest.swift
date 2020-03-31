import RequestSender
import Models

class RuntimeDumpRemoteCacheStoreRequest: NetworkRequest {
    typealias Response = VoidPayload

    public let httpMethod: HTTPMethod
    public let pathWithLeadingSlash: String
    public let payload: DiscoveredTests?

    public init(
        httpMethod: HTTPMethod,
        pathWithLeadingSlash: String,
        payload: DiscoveredTests
    ) {
        self.httpMethod = httpMethod
        self.pathWithLeadingSlash = pathWithLeadingSlash
        self.payload = payload
    }
}
