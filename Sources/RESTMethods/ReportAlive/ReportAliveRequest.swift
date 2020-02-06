import RequestSender
import Models

public final class ReportAliveRequest: NetworkRequest {
    public typealias Response = ReportAliveResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.reportAlive.withPrependingSlash

    public let payload: ReportAlivePayload?
    public init(payload: ReportAlivePayload) {
        self.payload = payload
    }
}
