import BucketQueue
import Foundation
import Logging
import Models
import ScheduleStrategy
import Timer

public final class StuckBucketsPoller {
    private let bucketQueue: BucketQueue
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(5))
    
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
        let stuckBuckets = bucketQueue.reenqueueStuckBuckets()
        
        guard !stuckBuckets.isEmpty else { return }
        
        log("Detected stuck buckets:")
        for stuckBucket in stuckBuckets {
            log("-- Bucket \(stuckBucket.bucket.bucketId) is stuck with worker '\(stuckBucket.workerId)': \(stuckBucket.reason)")
        }
        
        BucketQueueStateLogger(state: bucketQueue.state).logQueueSize()
    }
}
