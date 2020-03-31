import RequestSender
import Models

class RuntimeDumpRemoteCacheResultRequest: NetworkRequest {
    typealias Response = DiscoveredTests

    public let httpMethod: HTTPMethod
    public let pathWithLeadingSlash: String
    public let payload: VoidPayload? = nil

    public init(
        httpMethod: HTTPMethod,
        pathWithLeadingSlash: String
    ) {
        self.httpMethod = httpMethod
        self.pathWithLeadingSlash = pathWithLeadingSlash
    }
}
