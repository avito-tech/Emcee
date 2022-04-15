import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import DateProvider
import Foundation
import EmceeLogging
import MetricsRecording
import MetricsExtensions
import QueueModels
import ScheduleStrategy
import Timer

public final class StuckBucketsPoller {
    private let dateProvider: DateProvider
    private let globalMetricRecorder: GlobalMetricRecorder
    private let jobStateProvider: JobStateProvider
    private let logger: ContextualLogger
    private let queueHostname: String
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider
    private let statefulBucketQueue: StatefulBucketQueue
    private let stuckBucketsReenqueuer: StuckBucketsReenqueuer
    private let stuckBucketsTrigger = DispatchBasedTimer(repeating: .seconds(5), leeway: .seconds(5))
    private let version: Version
    
    public init(
        dateProvider: DateProvider,
        globalMetricRecorder: GlobalMetricRecorder,
        jobStateProvider: JobStateProvider,
        logger: ContextualLogger,
        queueHostname: String,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider,
        statefulBucketQueue: StatefulBucketQueue,
        stuckBucketsReenqueuer: StuckBucketsReenqueuer,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.globalMetricRecorder = globalMetricRecorder
        self.jobStateProvider = jobStateProvider
        self.logger = logger
        self.queueHostname = queueHostname
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
        self.statefulBucketQueue = statefulBucketQueue
        self.stuckBucketsReenqueuer = stuckBucketsReenqueuer
        self.version = version
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
                queueHost: queueHostname,
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
            queueHost: queueHostname,
            version: version
        )
        globalMetricRecorder.capture(
            queueStateMetricGatherer.metrics(
                jobStates: jobStateProvider.allJobStates,
                runningQueueState: statefulBucketQueue.runningQueueState
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
