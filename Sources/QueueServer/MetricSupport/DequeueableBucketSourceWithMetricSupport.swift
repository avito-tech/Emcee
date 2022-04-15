import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import DateProvider
import Foundation
import Graphite
import EmceeLogging
import MetricsRecording
import MetricsExtensions
import QueueModels
import WorkerCapabilitiesModels

public final class DequeueableBucketSourceWithMetricSupport: DequeueableBucketSource {
    private let dateProvider: DateProvider
    private let dequeueableBucketSource: DequeueableBucketSource
    private let jobStateProvider: JobStateProvider
    private let hostname: String
    private let logger: ContextualLogger
    private let statefulBucketQueue: StatefulBucketQueue
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider
    private let version: Version
    
    public init(
        dateProvider: DateProvider,
        dequeueableBucketSource: DequeueableBucketSource,
        jobStateProvider: JobStateProvider,
        hostname: String,
        logger: ContextualLogger,
        statefulBucketQueue: StatefulBucketQueue,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.dequeueableBucketSource = dequeueableBucketSource
        self.jobStateProvider = jobStateProvider
        self.hostname = hostname
        self.logger = logger
        self.statefulBucketQueue = statefulBucketQueue
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
        self.version = version
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
        let queueStateMetricGatherer = QueueStateMetricGatherer(
            dateProvider: dateProvider,
            queueHost: hostname,
            version: version
        )
        
        let queueStateMetrics = queueStateMetricGatherer.metrics(
            jobStates: jobStates,
            runningQueueState: statefulBucketQueue.runningQueueState
        )
        var bucketAndTestMetrics: [GraphiteMetric] = [
            DequeueBucketsMetric(
                workerId: workerId,
                version: version,
                queueHost: hostname,
                numberOfBuckets: 1,
                timestamp: dateProvider.currentDate()
            ),
            TimeToDequeueBucketMetric(
                version: version,
                queueHost: hostname,
                timeInterval: Date().timeIntervalSince(dequeuedBucket.enqueuedBucket.enqueueTimestamp),
                timestamp: dateProvider.currentDate()
            )
        ]
        
        bucketAndTestMetrics.append(
            DequeueTestsMetric(
                workerId: workerId,
                version: version,
                queueHost: hostname,
                numberOfTests: dequeuedBucket.enqueuedBucket.bucket.payloadContainer.payloadWithTests.testEntries.count,
                timestamp: dateProvider.currentDate()
            )
        )
        
        do {
            try specificMetricRecorderProvider.specificMetricRecorder(
                analyticsConfiguration: dequeuedBucket.enqueuedBucket.bucket.analyticsConfiguration
            ).capture(queueStateMetrics + bucketAndTestMetrics)
        } catch {
            logger.error("Failed to send metrics: \(error)")
        }
    }
}
