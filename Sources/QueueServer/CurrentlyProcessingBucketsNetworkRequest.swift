import DistWorkerModels
import Foundation
import RequestSender

public class CurrentlyProcessingBucketsNetworkRequest: NetworkRequest {
    public typealias Payload = VoidPayload
    public typealias Response = CurrentlyProcessingBucketsResponse
    
    public let httpMethod: HTTPMethod = .get
    public let pathWithLeadingSlash: String = CurrentlyProcessingBuckets.path.withLeadingSlash
    public let payload: VoidPayload? = VoidPayload()
    public let timeout: TimeInterval

    public init(timeout: TimeInterval) {
        self.timeout = timeout
    }
}
