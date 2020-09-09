import Foundation
import QueueModels
import RESTInterfaces

public final class BucketResultPayload: Codable, SignedPayload {
    public let bucketId: BucketId
    public let workerId: WorkerId
    public let testingResult: TestingResult
    public let payloadSignature: PayloadSignature
    
    public init(
        bucketId: BucketId,
        workerId: WorkerId,
        testingResult: TestingResult,
        payloadSignature: PayloadSignature
    ) {
        self.bucketId = bucketId
        self.workerId = workerId
        self.testingResult = testingResult
        self.payloadSignature = payloadSignature
    }
}
