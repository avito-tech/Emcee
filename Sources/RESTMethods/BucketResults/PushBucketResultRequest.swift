import Foundation
import Models

public final class PushBucketResultRequest: Codable, SignedRequest {
    public let workerId: WorkerId
    public let requestId: RequestId
    public let testingResult: TestingResult
    public let requestSignature: RequestSignature
    
    public init(
        workerId: WorkerId,
        requestId: RequestId,
        testingResult: TestingResult,
        requestSignature: RequestSignature
    ) {
        self.workerId = workerId
        self.requestId = requestId
        self.testingResult = testingResult
        self.requestSignature = requestSignature
    }
}
