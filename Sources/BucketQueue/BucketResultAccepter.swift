import Foundation
import Models

public protocol BucketResultAccepter {
    func accept(testingResult: TestingResult, requestId: RequestId, workerId: WorkerId) throws -> BucketQueueAcceptResult
}
