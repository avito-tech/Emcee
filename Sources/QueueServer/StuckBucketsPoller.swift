import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import DateProvider
import Foundation
import LocalHostDeterminer
import EmceeLogging
import Metrics
import MetricsExtensions
import QueueModels
import ScheduleStrategy
import Timer

public final class StuckBucketsPoller {
    private let dateProvider: DateProvider
    private let jobStateProvider: JobStateProvider
    private let logger: ContextualLogger
    private let runningQueueStateProvider: RunningQueueStateProvider
    private let stuckBucketsReenqueuer: StuckBucketsReenqueuer
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(1), leeway: .seconds(5))
    private let version: Version
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider
    private let globalMetricRecorder: GlobalMetricRecorder
    
    public init(
        dateProvider: DateProvider,
        jobStateProvider: JobStateProvider,
        logger: ContextualLogger,
        runningQueueStateProvider: RunningQueueStateProvider,
        stuckBucketsReenqueuer: StuckBucketsReenqueuer,
        version: Version,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider,
        globalMetricRecorder: GlobalMetricRecorder
    ) {
        self.dateProvider = dateProvider
        self.jobStateProvider = jobStateProvider
        self.logger = logger
        self.runningQueueStateProvider = runningQueueStateProvider
        self.stuckBucketsReenqueuer = stuckBucketsReenqueuer
        self.version = version
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
        self.globalMetricRecorder = globalMetricRecorder
    }
    
    public func startTrackingStuckBuckets() {
        stuckBucketsTrigger.start { [weak self] _ in
            self?.processStuckBuckets()
        }
    }
    
    /// internal for testing
    func processStuckBuckets() {
        let stuckBuckets: [StuckBucket]
        do {
            stuckBuckets = try stuckBucketsReenqueuer.reenqueueStuckBuckets()
        } catch {
            return logger.error("Failed to reenqueue stuck buckets: \(error)")
        }
        
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
        
        logger.warning("Detected stuck buckets:")
        for stuckBucket in stuckBuckets {
            logger.warning("-- Bucket \(stuckBucket.bucket.bucketId) is stuck with worker '\(stuckBucket.workerId)': \(stuckBucket.reason)")
            do {
                try specificMetricRecorderProvider.specificMetricRecorder(
                    analyticsConfiguration: stuckBucket.bucket.analyticsConfiguration
                ).capture(stuckBucketMetrics)
            } catch {
                logger.error("Failed to send metrics: \(error)")
            }
        }
        
        let queueStateMetricGatherer = QueueStateMetricGatherer(
            dateProvider: dateProvider,
            version: version
        )
        globalMetricRecorder.capture(
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
