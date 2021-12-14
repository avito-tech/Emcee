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
            switch dequeuedBucket.enqueuedBucket.bucket.payloadContainer {
            case .runIosTests(let runIosTestsPayload):
                dequeuedTests.append(
                    key: dequeuedBucket.workerId,
                    elements: runIosTestsPayload.testEntries.map { $0.testName }
                )
            case .runAndroidTests(let runAndroidTestsPayload):
                dequeuedTests.append(
                    key: dequeuedBucket.workerId,
                    elements: runAndroidTestsPayload.testEntries.map { $0.testName }
                )
            }
        }
        
        let enqueuedTests = enqueuedBuckets
            .flatMap { enqueuedBucket -> [TestEntry] in
                switch enqueuedBucket.bucket.payloadContainer {
                case .runIosTests(let runIosTestsPayload):
                    return runIosTestsPayload.testEntries
                case .runAndroidTests(let runAndroidTestsPayload):
                    return runAndroidTestsPayload.testEntries
                }
            }
            .map(\.testName)
        
        return RunningQueueState(
            enqueuedBucketCount: enqueuedBuckets.count,
            enqueuedTests: enqueuedTests,
            dequeuedBucketCount: dequeuedBuckets.count,
            dequeuedTests: dequeuedTests
        )
    }
}
