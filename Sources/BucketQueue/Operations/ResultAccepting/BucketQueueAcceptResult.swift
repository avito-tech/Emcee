import BucketQueueModels
import Foundation
import QueueModels
import TestHistoryModels

public final class BucketQueueAcceptResult {
    
    public let dequeuedBucket: DequeuedBucket
    
    // Not every result is ready to collect,
    // this may be due to retrying
    public let bucketResultToCollect: BucketResult
    
    public init(dequeuedBucket: DequeuedBucket, bucketResultToCollect: BucketResult) {
        self.dequeuedBucket = dequeuedBucket
        self.bucketResultToCollect = bucketResultToCollect
    }
}
