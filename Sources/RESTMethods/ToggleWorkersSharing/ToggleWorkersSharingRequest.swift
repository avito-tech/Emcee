import RESTInterfaces
import RequestSender

public struct ToggleWorkersSharingRequest: NetworkRequest {
    public typealias Response = VoidPayload

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.toggleWorkersSharing.pathWithLeadingSlash

    
    public let payload: ToggleWorkersSharingPayload?
    public init(payload: ToggleWorkersSharingPayload) {
        self.payload = payload
    }
}
