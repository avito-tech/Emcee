import RESTInterfaces
import RequestSender

public final class ScheduleTestsRequest: NetworkRequest {
    public typealias Response = ScheduleTestsResponse

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.scheduleTests.pathWithLeadingSlash

    public let payload: ScheduleTestsPayload?
    public init(payload: ScheduleTestsPayload) {
        self.payload = payload
    }
}
