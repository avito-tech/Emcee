import Foundation
import Models
import QueueModels

public protocol BucketResultAccepter {
    func accept(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId
    ) throws -> BucketQueueAcceptResult
}
