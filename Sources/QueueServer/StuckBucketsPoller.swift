import BucketQueue
import Foundation
import Logging
import Models
import ScheduleStrategy
import Timer

public final class StuckBucketsPoller {
    private let statefulStuckBucketsReenqueuer: StuckBucketsReenqueuer & QueueStateProvider
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(5))
    
    public init(statefulStuckBucketsReenqueuer: StuckBucketsReenqueuer & QueueStateProvider) {
        self.statefulStuckBucketsReenqueuer = statefulStuckBucketsReenqueuer
    }
    
    public func startTrackingStuckBuckets() {
        stuckBucketsTrigger.start { [weak self] _ in
            self?.processStuckBuckets()
        }
    }
    
    /// internal for testing
    func processStuckBuckets() {
        let stuckBuckets = statefulStuckBucketsReenqueuer.reenqueueStuckBuckets()
        
        guard !stuckBuckets.isEmpty else { return }
        
        Logger.warning("Detected stuck buckets:")
        for stuckBucket in stuckBuckets {
            Logger.warning("-- Bucket \(stuckBucket.bucket.bucketId) is stuck with worker '\(stuckBucket.workerId)': \(stuckBucket.reason)")
        }
        BucketQueueStateLogger(state: statefulStuckBucketsReenqueuer.state).logQueueSize()
    }
}
