import Foundation
import QueueModels
import RESTInterfaces

public final class BucketResultPayload: Codable, SignedPayload {
    public let bucketId: BucketId
    public let workerId: WorkerId
    public let bucketResult: BucketResult
    public let payloadSignature: PayloadSignature
    
    public init(
        bucketId: BucketId,
        workerId: WorkerId,
        bucketResult: BucketResult,
        payloadSignature: PayloadSignature
    ) {
        self.bucketId = bucketId
        self.workerId = workerId
        self.bucketResult = bucketResult
        self.payloadSignature = payloadSignature
    }
}
