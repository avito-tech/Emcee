import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels

open class FakeTestingResultAcceptor: TestingResultAcceptor {
    public var handler: (DequeuedBucket, RunIosTestsPayload, TestingResult) throws -> TestingResult
    
    public init(
        handler: @escaping (DequeuedBucket, RunIosTestsPayload, TestingResult) throws -> TestingResult = { _, _, testingResult in
            testingResult
        }
    ) {
        self.handler = handler
    }
    
    public func acceptTestingResult(
        dequeuedBucket: DequeuedBucket,
        runIosTestsPayload: RunIosTestsPayload,
        testingResult: TestingResult
    ) throws -> TestingResult {
        try handler(dequeuedBucket, runIosTestsPayload, testingResult)
    }
}
