import Foundation
import QueueModels

public protocol BucketQueue: BucketEnqueuer, BucketResultAccepter, DequeueableBucketSource, EmptyableBucketQueue, RunningQueueStateProvider, StuckBucketsReenqueuer {
    
}
