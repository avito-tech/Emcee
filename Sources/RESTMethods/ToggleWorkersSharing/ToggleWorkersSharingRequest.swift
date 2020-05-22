import Models
import RESTInterfaces
import RequestSender

public struct ToggleWorkersSharingRequest: NetworkRequest {
    public typealias Response = VoidPayload

    public let httpMethod = HTTPMethod.post
    public let pathWithLeadingSlash = RESTMethod.toggleWorkersSharing.pathWithLeadingSlash

    
    public let payload: WorkersSharingFeatureStatus?
    public init(payload: WorkersSharingFeatureStatus) {
        self.payload = payload
    }
}
