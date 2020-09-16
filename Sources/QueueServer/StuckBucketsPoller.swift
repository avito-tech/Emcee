import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
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
    private let jobStateProvider: JobStateProvider
    private let runningQueueStateProvider: RunningQueueStateProvider
    private let stuckBucketsReenqueuer: StuckBucketsReenqueuer
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(5))
    private let version: Version
    private let metricRecorder: MetricRecorder
    
    public init(
        dateProvider: DateProvider,
        jobStateProvider: JobStateProvider,
        runningQueueStateProvider: RunningQueueStateProvider,
        stuckBucketsReenqueuer: StuckBucketsReenqueuer,
        version: Version,
        metricRecorder: MetricRecorder
    ) {
        self.dateProvider = dateProvider
        self.jobStateProvider = jobStateProvider
        self.runningQueueStateProvider = runningQueueStateProvider
        self.stuckBucketsReenqueuer = stuckBucketsReenqueuer
        self.version = version
        self.metricRecorder = metricRecorder
    }
    
    public func startTrackingStuckBuckets() {
        stuckBucketsTrigger.start { [weak self] _ in
            self?.processStuckBuckets()
        }
    }
    
    /// internal for testing
    func processStuckBuckets() {
        let stuckBuckets = stuckBucketsReenqueuer.reenqueueStuckBuckets()
        
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
        metricRecorder.capture(stuckBucketMetrics)
        
        Logger.warning("Detected stuck buckets:")
        for stuckBucket in stuckBuckets {
            Logger.warning("-- Bucket \(stuckBucket.bucket.bucketId) is stuck with worker '\(stuckBucket.workerId)': \(stuckBucket.reason)")
        }
        
        let queueStateMetricGatherer = QueueStateMetricGatherer(
            dateProvider: dateProvider,
            version: version
        )
        
        metricRecorder.capture(
            queueStateMetricGatherer.metrics(
                jobStates: jobStateProvider.allJobStates,
                runningQueueState: runningQueueStateProvider.runningQueueState
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
