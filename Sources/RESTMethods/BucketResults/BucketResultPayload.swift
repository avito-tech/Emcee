import Foundation
import QueueModels
import RESTInterfaces

public final class BucketResultPayload: Codable, SignedPayload {
    public let workerId: WorkerId
    public let requestId: RequestId
    public let testingResult: TestingResult
    public let payloadSignature: PayloadSignature
    
    public init(
        workerId: WorkerId,
        requestId: RequestId,
        testingResult: TestingResult,
        payloadSignature: PayloadSignature
    ) {
        self.workerId = workerId
        self.requestId = requestId
        self.testingResult = testingResult
        self.payloadSignature = payloadSignature
    }
}
