import BalancingBucketQueue
import BucketQueue
import Foundation
import Logging
import Metrics
import Models
import ScheduleStrategy
import Timer

public final class StuckBucketsPoller {
    private let statefulStuckBucketsReenqueuer: StuckBucketsReenqueuer & JobStateProvider & RunningQueueStateProvider
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(5))
    
    public init(statefulStuckBucketsReenqueuer: StuckBucketsReenqueuer & JobStateProvider & RunningQueueStateProvider) {
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
        
        let stuckBucketMetrics: [StuckBucketsMetric] = stuckBuckets.map {
            return StuckBucketsMetric(count: 1, host: $0.workerId, reason: $0.reason.metricParameterName)
        }
        MetricRecorder.capture(stuckBucketMetrics)
        
        Logger.warning("Detected stuck buckets:")
        for stuckBucket in stuckBuckets {
            Logger.warning("-- Bucket \(stuckBucket.bucket.bucketId) is stuck with worker '\(stuckBucket.workerId)': \(stuckBucket.reason)")
        }
        
        BucketQueueStateLogger(runningQueueState: statefulStuckBucketsReenqueuer.runningQueueState).logQueueSize()
        MetricRecorder.capture(
            QueueStateMetricGatherer.metrics(
                jobStates: statefulStuckBucketsReenqueuer.allJobStates,
                runningQueueState: statefulStuckBucketsReenqueuer.runningQueueState
            )
        )
    }
}

private extension StuckBucket.Reason {
    var metricParameterName: String {
        switch self {
        case .workerIsSilent: return "workerIsSilent"
        case .workerIsBlocked: return "workerIsBlocked"
        case .bucketLost: return "bucketLost"
        }
    }
}
