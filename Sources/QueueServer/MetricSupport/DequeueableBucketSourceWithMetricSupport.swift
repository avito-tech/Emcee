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
import WorkerCapabilitiesModels

public final class DequeueableBucketSourceWithMetricSupport: DequeueableBucketSource {
    private let dateProvider: DateProvider
    private let dequeueableBucketSource: DequeueableBucketSource
    private let jobStateProvider: JobStateProvider
    private let queueStateProvider: RunningQueueStateProvider
    private let version: Version
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider
    
    public init(
        dateProvider: DateProvider,
        dequeueableBucketSource: DequeueableBucketSource,
        jobStateProvider: JobStateProvider,
        queueStateProvider: RunningQueueStateProvider,
        version: Version,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider
    ) {
        self.dateProvider = dateProvider
        self.dequeueableBucketSource = dequeueableBucketSource
        self.jobStateProvider = jobStateProvider
        self.queueStateProvider = queueStateProvider
        self.version = version
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
    }
    
    public func dequeueBucket(workerCapabilities: Set<WorkerCapability>, workerId: WorkerId) -> DequeuedBucket? {
        let dequeuedBucket = dequeueableBucketSource.dequeueBucket(workerCapabilities: workerCapabilities, workerId: workerId)
        
        if let dequeuedBucket = dequeuedBucket {
            sendMetrics(
                dequeuedBucket: dequeuedBucket,
                workerId: workerId
            )
        }
        return dequeuedBucket
    }
    
    private func sendMetrics(
        dequeuedBucket: DequeuedBucket,
        workerId: WorkerId
    ) {
        let jobStates = jobStateProvider.allJobStates
        let runningQueueState = queueStateProvider.runningQueueState
        let queueStateMetricGatherer = QueueStateMetricGatherer(dateProvider: dateProvider, version: version)
        
        let queueStateMetrics = queueStateMetricGatherer.metrics(
            jobStates: jobStates,
            runningQueueState: runningQueueState
        )
        let bucketAndTestMetrics = [
            DequeueBucketsMetric(
                workerId: workerId,
                version: version,
                queueHost: LocalHostDeterminer.currentHostAddress,
                numberOfBuckets: 1,
                timestamp: dateProvider.currentDate()
            ),
            DequeueTestsMetric(
                workerId: workerId,
                version: version,
                queueHost: LocalHostDeterminer.currentHostAddress,
                numberOfTests: dequeuedBucket.enqueuedBucket.bucket.testEntries.count,
                timestamp: dateProvider.currentDate()
            ),
            TimeToDequeueBucketMetric(
                version: version,
                queueHost: LocalHostDeterminer.currentHostAddress,
                timeInterval: Date().timeIntervalSince(dequeuedBucket.enqueuedBucket.enqueueTimestamp),
                timestamp: dateProvider.currentDate()
            )
        ]
        
        do {
            try specificMetricRecorderProvider.specificMetricRecorder(
                analyticsConfiguration: dequeuedBucket.enqueuedBucket.bucket.analyticsConfiguration
            ).capture(queueStateMetrics + bucketAndTestMetrics)
        } catch {
            Logger.error("Failed to send metrics: \(error)")
        }
    }
}
