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
                bucketId: dequeuedBucket.bucket.bucketId,
                workerId: decodedRequest.workerId
            )
            let state = statefulDequeueableBucketSource.state
            BucketQueueStateLogger(state: state).logQueueSize()
            sendMetrics(
                workerId: decodedRequest.workerId,
                numberOfTests: dequeuedBucket.bucket.testEntries.count,
                state: state
            )
            return .bucketDequeued(bucket: dequeuedBucket.bucket)
        case .workerBlocked:
            return .workerBlocked
        }
    }
    
    private func sendMetrics(workerId: String, numberOfTests: Int, state: QueueState) {
        MetricRecorder.capture(
            DequeueBucketsMetric(workerId: workerId, numberOfBuckets: 1)
        )
        MetricRecorder.capture(
            DequeueTestsMetric(workerId: workerId, numberOfTests: numberOfTests)
        )
        QueueStateMetricRecorder(state: state).capture()
    }
}
