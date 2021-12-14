import Foundation
import QueueModels
import RunnerModels
import Types


public final class SingleStatefulBucketQueue: StatefulBucketQueue {
    private let bucketQueueHolder: BucketQueueHolder
    
    public init(bucketQueueHolder: BucketQueueHolder) {
        self.bucketQueueHolder = bucketQueueHolder
    }
    
    public var runningQueueState: RunningQueueState {
        let dequeuedBuckets = bucketQueueHolder.allDequeuedBuckets
        let enqueuedBuckets = bucketQueueHolder.allEnqueuedBuckets
        
        var dequeuedTests = MapWithCollection<WorkerId, TestName>()
        for dequeuedBucket in dequeuedBuckets {
            if let runIosTestsPayload = try? dequeuedBucket.enqueuedBucket.bucket.payload.cast(RunIosTestsPayload.self) {
                dequeuedTests.append(
                    key: dequeuedBucket.workerId,
                    elements: runIosTestsPayload.testEntries.map { $0.testName }
                )
            }
        }
        
        let enqueuedTests = enqueuedBuckets
            .compactMap { enqueuedBucket in
                try? enqueuedBucket.bucket.payload.cast(RunIosTestsPayload.self)
            }
            .flatMap(\.testEntries)
            .map(\.testName)
        
        return RunningQueueState(
            enqueuedBucketCount: enqueuedBuckets.count,
            enqueuedTests: enqueuedTests,
            dequeuedBucketCount: dequeuedBuckets.count,
            dequeuedTests: dequeuedTests
        )
    }
}
