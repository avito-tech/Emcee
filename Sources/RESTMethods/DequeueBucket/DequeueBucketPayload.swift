import Foundation
import Models

public final class DequeueBucketPayload: Codable, SignedPayload {
    public let workerId: WorkerId
    public let requestId: RequestId
    public let payloadSignature: PayloadSignature
    
    public init(workerId: WorkerId, requestId: RequestId, requestSignature: PayloadSignature) {
        self.workerId = workerId
        self.requestId = requestId
        self.payloadSignature = requestSignature
    }
}
