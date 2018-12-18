import Foundation
import Models

public protocol BucketResultAccepter {
    func accept(testingResult: TestingResult, requestId: String, workerId: String) throws -> BucketQueueAcceptResult
}
