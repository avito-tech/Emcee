import Foundation
import Models

public final class DequeueBucketRequest: Codable, SignedRequest {
    public let workerId: WorkerId
    public let requestId: RequestId
    public let requestSignature: RequestSignature
    
    public init(workerId: WorkerId, requestId: RequestId, requestSignature: RequestSignature) {
        self.workerId = workerId
        self.requestId = requestId
        self.requestSignature = requestSignature
    }
}
