import BucketQueue
import Foundation
import Logging
import Models
import ScheduleStrategy
import Timer

public final class StuckBucketsEnqueuer {
    private let bucketQueue: BucketQueue
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(5))
    private let individualSplitter = IndividualBucketSplitter()
    
    public init(bucketQueue: BucketQueue) {
        self.bucketQueue = bucketQueue
    }
    
    public func startTrackingStuckBuckets() {
        stuckBucketsTrigger.start { [weak self] in
            self?.processStuckBuckets()
        }
    }
    
    /// internal for testing
    func processStuckBuckets() {
        let stuckBuckets = bucketQueue.removeStuckBuckets()
        guard !stuckBuckets.isEmpty else { return }
        
        log("Detected stuck buckets:")
        for stuckBucket in stuckBuckets {
            log("-- Bucket \(stuckBucket.bucket.bucketId) is stuck with worker '\(stuckBucket.workerId)': \(stuckBucket.reason)")
        }

        let buckets = stuckBuckets.flatMap {
            individualSplitter.generate(
                inputs: $0.bucket.testEntries,
                splitInfo: BucketSplitInfo(
                    numberOfDestinations: 1,
                    testDestinations: [$0.bucket.testDestination],
                    toolResources: $0.bucket.toolResources,
                    buildArtifacts: $0.bucket.buildArtifacts))
        }
        bucketQueue.enqueue(buckets: buckets)
        log("Returned \(stuckBuckets.count) stuck buckets to the queue by crushing it to \(buckets.count) buckets:")
        for bucket in buckets {
            log("-- \(bucket)")
        }
        BucketQueueStateLogger(state: bucketQueue.state).logQueueSize()
    }
}
