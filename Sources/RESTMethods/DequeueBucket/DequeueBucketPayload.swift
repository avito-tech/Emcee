import Foundation
import QueueModels
import RESTInterfaces

public final class DequeueBucketPayload: Codable, SignedPayload {
    public let workerId: WorkerId
    public let requestId: RequestId
    public let payloadSignature: PayloadSignature
    
    public init(workerId: WorkerId, requestId: RequestId, payloadSignature: PayloadSignature) {
        self.workerId = workerId
        self.requestId = requestId
        self.payloadSignature = payloadSignature
    }
}
