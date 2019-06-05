import Foundation
import Models

public final class PushBucketResultRequest: Codable, SignedRequest {
    public let workerId: String
    public let requestId: String
    public let testingResult: TestingResult
    public let requestSignature: RequestSignature
    
    public init(
        workerId: String,
        requestId: String,
        testingResult: TestingResult,
        requestSignature: RequestSignature
    ) {
        self.workerId = workerId
        self.requestId = requestId
        self.testingResult = testingResult
        self.requestSignature = requestSignature
    }
}
