import BucketQueueModels
import Foundation
import QueueModels
import TestHistoryModels

public final class BucketQueueAcceptResult {
    
    public let dequeuedBucket: DequeuedBucket
    
    // Not every result is ready to collect,
    // this may be due to retrying
    public let testingResultToCollect: TestingResult
    
    public init(dequeuedBucket: DequeuedBucket, testingResultToCollect: TestingResult) {
        self.dequeuedBucket = dequeuedBucket
        self.testingResultToCollect = testingResultToCollect
    }
}
