import Foundation
import Models

public final class DequeueBucketRequest: Codable, SignedRequest {
    public let workerId: String
    public let requestId: String
    public let requestSignature: RequestSignature
    
    public init(workerId: String, requestId: String, requestSignature: RequestSignature) {
        self.workerId = workerId
        self.requestId = requestId
        self.requestSignature = requestSignature
    }
}
