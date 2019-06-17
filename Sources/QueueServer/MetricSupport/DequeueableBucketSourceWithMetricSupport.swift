import BalancingBucketQueue
import BucketQueue
import Foundation
import Metrics

public final class DequeueableBucketSourceWithMetricSupport: DequeueableBucketSource {
    private let dequeueableBucketSource: DequeueableBucketSource
    private let jobStateProvider: JobStateProvider
    private let queueStateProvider: RunningQueueStateProvider

    public init(
        dequeueableBucketSource: DequeueableBucketSource,
        jobStateProvider: JobStateProvider,
        queueStateProvider: RunningQueueStateProvider
        )
    {
        self.dequeueableBucketSource = dequeueableBucketSource
        self.jobStateProvider = jobStateProvider
        self.queueStateProvider = queueStateProvider
    }
    
    public func previouslyDequeuedBucket(requestId: String, workerId: String) -> DequeuedBucket? {
        return dequeueableBucketSource.previouslyDequeuedBucket(requestId: requestId, workerId: workerId)
    }
    
    public func dequeueBucket(requestId: String, workerId: String) -> DequeueResult {
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
        workerId: String
    ) {
        let jobStates = jobStateProvider.allJobStates
        let runningQueueState = queueStateProvider.runningQueueState
        BucketQueueStateLogger(runningQueueState: runningQueueState).logQueueSize()
        
        let queueStateMetrics = QueueStateMetricGatherer.metrics(
            jobStates: jobStates,
            runningQueueState: runningQueueState
        )
        let bucketAndTestMetrics = [
            DequeueBucketsMetric(workerId: workerId, numberOfBuckets: 1),
            DequeueTestsMetric(workerId: workerId, numberOfTests: dequeuedBucket.enqueuedBucket.bucket.testEntries.count),
            TimeToDequeueBucket(timeInterval: Date().timeIntervalSince(dequeuedBucket.enqueuedBucket.enqueueTimestamp))
        ]
        MetricRecorder.capture(queueStateMetrics + bucketAndTestMetrics)
    }
}
