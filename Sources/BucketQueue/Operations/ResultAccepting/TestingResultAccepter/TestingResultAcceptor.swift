import BucketQueueModels
import EmceeLogging
import Foundation
import QueueModels

public protocol TestingResultAcceptor {
    func acceptTestingResult(
        dequeuedBucket: DequeuedBucket,
        bucketPayloadWithTests: BucketPayloadWithTests,
        testingResult: TestingResult
    ) throws -> TestingResult
}
