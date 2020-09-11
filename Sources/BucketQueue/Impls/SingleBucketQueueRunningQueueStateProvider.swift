import Foundation
import QueueModels
import RunnerModels
import Types


public final class SingleBucketQueueRunningQueueStateProvider: RunningQueueStateProvider {
    private let bucketQueueHolder: BucketQueueHolder
    
    public init(bucketQueueHolder: BucketQueueHolder) {
        self.bucketQueueHolder = bucketQueueHolder
    }
    
    public var runningQueueState: RunningQueueState {
        let dequeuedBuckets = bucketQueueHolder.allDequeuedBuckets
        let enqueuedBuckets = bucketQueueHolder.allEnqueuedBuckets
        
        var dequeuedTests = MapWithCollection<WorkerId, TestName>()
        for dequeuedBucket in dequeuedBuckets {
            dequeuedTests.append(
                key: dequeuedBucket.workerId,
                elements: dequeuedBucket.enqueuedBucket.bucket.testEntries.map { $0.testName }
            )
        }
        
        return RunningQueueState(
            enqueuedBucketCount: enqueuedBuckets.count,
            enqueuedTests: enqueuedBuckets.flatMap { $0.bucket.testEntries.map { $0.testName } },
            dequeuedBucketCount: dequeuedBuckets.count,
            dequeuedTests: dequeuedTests
        )
    }
}
