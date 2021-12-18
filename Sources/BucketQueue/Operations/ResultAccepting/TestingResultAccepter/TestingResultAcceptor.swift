import BucketQueueModels
import EmceeLogging
import Foundation
import QueueModels

public protocol TestingResultAcceptor {
    func acceptTestingResult(
        dequeuedBucket: DequeuedBucket,
        runIosTestsPayload: RunIosTestsPayload,
        testingResult: TestingResult
    ) throws -> TestingResult
}
