import BalancingBucketQueue
import BucketQueue
import DateProvider
import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import QueueModels
import ScheduleStrategy
import Timer

public final class StuckBucketsPoller {
    private let dateProvider: DateProvider
    private let statefulStuckBucketsReenqueuer: StuckBucketsReenqueuer & JobStateProvider & RunningQueueStateProvider
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(5))
    private let version: Version
    
    public init(
        dateProvider: DateProvider,
        statefulStuckBucketsReenqueuer: StuckBucketsReenqueuer & JobStateProvider & RunningQueueStateProvider,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.statefulStuckBucketsReenqueuer = statefulStuckBucketsReenqueuer
        self.version = version
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
            StuckBucketsMetric(
                workerId: $0.workerId,
                reason: $0.reason.metricParameterName,
                version: version,
                queueHost: LocalHostDeterminer.currentHostAddress,
                count: 1,
                timestamp: dateProvider.currentDate()
            )
        }
        MetricRecorder.capture(stuckBucketMetrics)
        
        Logger.warning("Detected stuck buckets:")
        for stuckBucket in stuckBuckets {
            Logger.warning("-- Bucket \(stuckBucket.bucket.bucketId) is stuck with worker '\(stuckBucket.workerId)': \(stuckBucket.reason)")
        }
        
        let queueStateMetricGatherer = QueueStateMetricGatherer(
            dateProvider: dateProvider,
            version: version
        )
        
        MetricRecorder.capture(
            queueStateMetricGatherer.metrics(
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
        case .bucketLost: return "bucketLost"
        }
    }
}
