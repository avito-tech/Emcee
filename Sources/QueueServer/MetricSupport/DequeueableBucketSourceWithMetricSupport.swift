import BalancingBucketQueue
import BucketQueue
import DateProvider
import Foundation
import LocalHostDeterminer
import Metrics
import Models

public final class DequeueableBucketSourceWithMetricSupport: DequeueableBucketSource {
    private let dateProvider: DateProvider
    private let dequeueableBucketSource: DequeueableBucketSource
    private let jobStateProvider: JobStateProvider
    private let queueStateProvider: RunningQueueStateProvider
    private let version: Version

    public init(
        dateProvider: DateProvider,
        dequeueableBucketSource: DequeueableBucketSource,
        jobStateProvider: JobStateProvider,
        queueStateProvider: RunningQueueStateProvider,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.dequeueableBucketSource = dequeueableBucketSource
        self.jobStateProvider = jobStateProvider
        self.queueStateProvider = queueStateProvider
        self.version = version
    }
    
    public func previouslyDequeuedBucket(requestId: RequestId, workerId: WorkerId) -> DequeuedBucket? {
        return dequeueableBucketSource.previouslyDequeuedBucket(requestId: requestId, workerId: workerId)
    }
    
    public func dequeueBucket(requestId: RequestId, workerId: WorkerId) -> DequeueResult {
        let dequeueResult = dequeueableBucketSource.dequeueBucket(requestId: requestId, workerId: workerId)
        
        if case DequeueResult.dequeuedBucket(let dequeuedBucket) = dequeueResult {
            sendMetrics(
                dequeuedBucket: dequeuedBucket,
                workerId: workerId
            )
        }
        
        return dequeueResult
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
        MetricRecorder.capture(queueStateMetrics + bucketAndTestMetrics)
    }
}
