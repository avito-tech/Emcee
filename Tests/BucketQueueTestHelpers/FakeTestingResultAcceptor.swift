import BucketQueue
import BucketQueueModels
import Foundation
import QueueModels

open class FakeTestingResultAcceptor: TestingResultAcceptor {
    public var handler: (DequeuedBucket, TestingResult) throws -> TestingResult
    
    public init(
        handler: @escaping (DequeuedBucket, TestingResult) throws -> TestingResult = { _, testingResult in
            testingResult
        }
    ) {
        self.handler = handler
    }
    
    public func acceptTestingResult(
        dequeuedBucket: DequeuedBucket,
        testingResult: TestingResult
    ) throws -> TestingResult {
        try handler(dequeuedBucket, testingResult)
    }
}
