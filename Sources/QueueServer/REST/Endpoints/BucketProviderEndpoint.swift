import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import Metrics
import RESTMethods
import WorkerAlivenessTracker

public final class BucketProviderEndpoint: RESTEndpoint {
    private let statefulDequeueableBucketSource: DequeueableBucketSource & QueueStateProvider
    private let workerAlivenessTracker: WorkerAlivenessTracker

    public init(
        statefulDequeueableBucketSource: DequeueableBucketSource & QueueStateProvider,
        workerAlivenessTracker: WorkerAlivenessTracker)
    {
        self.statefulDequeueableBucketSource = statefulDequeueableBucketSource
        self.workerAlivenessTracker = workerAlivenessTracker
    }
    
    public func handle(decodedRequest: DequeueBucketRequest) throws -> DequeueBucketResponse {
        workerAlivenessTracker.markWorkerAsAlive(workerId: decodedRequest.workerId)
        
        let dequeueResult = statefulDequeueableBucketSource.dequeueBucket(
            requestId: decodedRequest.requestId,
            workerId: decodedRequest.workerId
        )
        
        switch dequeueResult {
        case .queueIsEmpty:
            return .queueIsEmpty
        case .checkAgainLater(let checkAfter):
            return .checkAgainLater(checkAfter: checkAfter)
        case .dequeuedBucket(let dequeuedBucket):
            workerAlivenessTracker.didDequeueBucket(
                bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
                workerId: decodedRequest.workerId
            )
            let state = statefulDequeueableBucketSource.state
            BucketQueueStateLogger(state: state).logQueueSize()
            sendMetrics(
                workerId: decodedRequest.workerId,
                dequeuedBucket: dequeuedBucket,
                state: state
            )
            return .bucketDequeued(bucket: dequeuedBucket.enqueuedBucket.bucket)
        case .workerBlocked:
            return .workerBlocked
        }
    }
    
    private func sendMetrics(
        workerId: String,
        dequeuedBucket: DequeuedBucket,
        state: QueueState)
    {
        MetricRecorder.capture(
            DequeueBucketsMetric(workerId: workerId, numberOfBuckets: 1),
            DequeueTestsMetric(workerId: workerId, numberOfTests: dequeuedBucket.enqueuedBucket.bucket.testEntries.count),
            TimeToDequeueBucket(timeInterval: Date().timeIntervalSince(dequeuedBucket.enqueuedBucket.enqueueTimestamp))
        )
        
        QueueStateMetricRecorder(state: state).capture()
    }
}
