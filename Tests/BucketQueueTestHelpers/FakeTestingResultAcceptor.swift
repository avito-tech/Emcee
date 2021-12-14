import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels

open class FakeTestingResultAcceptor: TestingResultAcceptor {
    public var handler: (DequeuedBucket, BucketPayloadWithTests, TestingResult) throws -> TestingResult
    
    public init(
        handler: @escaping (DequeuedBucket, BucketPayloadWithTests, TestingResult) throws -> TestingResult = { _, _, testingResult in
            testingResult
        }
    ) {
        self.handler = handler
    }
    
    public func acceptTestingResult(
        dequeuedBucket: DequeuedBucket,
        bucketPayloadWithTests: BucketPayloadWithTests,
        testingResult: TestingResult
    ) throws -> TestingResult {
        try handler(dequeuedBucket, bucketPayloadWithTests, testingResult)
    }
}
