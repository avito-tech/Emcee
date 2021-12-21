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
            switch dequeuedBucket.enqueuedBucket.bucket.payload {
            case .runIosTests(let runIosTestsPayload):
                dequeuedTests.append(
                    key: dequeuedBucket.workerId,
                    elements: runIosTestsPayload.testEntries.map { $0.testName }
                )
            case .ping:
                break
            }
        }
        
        let enqueuedTests = enqueuedBuckets
            .compactMap { enqueuedBucket -> RunIosTestsPayload? in
                switch enqueuedBucket.bucket.payload {
                case .runIosTests(let runIosTestsPayload):
                    return runIosTestsPayload
                case .ping:
                    return nil
                }
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
