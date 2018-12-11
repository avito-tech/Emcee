import Foundation
import Models

public final class PushBucketResultRequest: Codable {
    public let workerId: String
    public let requestId: String
    public let testingResult: TestingResult
    
    public init(workerId: String, requestId: String, testingResult: TestingResult) {
        self.workerId = workerId
        self.requestId = requestId
        self.testingResult = testingResult
    }
}
