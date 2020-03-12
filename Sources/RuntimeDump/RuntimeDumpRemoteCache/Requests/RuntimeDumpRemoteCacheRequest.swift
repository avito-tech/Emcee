import RequestSender
import Models

class RuntimeDumpRemoteCacheStoreRequest: NetworkRequest {
    typealias Response = VoidPayload

    public let httpMethod: HTTPMethod
    public let pathWithLeadingSlash: String
    public let payload: TestsInRuntimeDump?

    public init(
        httpMethod: HTTPMethod,
        pathWithLeadingSlash: String,
        payload: TestsInRuntimeDump
    ) {
        self.httpMethod = httpMethod
        self.pathWithLeadingSlash = pathWithLeadingSlash
        self.payload = payload
    }
}
