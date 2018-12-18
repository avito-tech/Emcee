import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
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
            BucketQueueStateLogger(state: statefulDequeueableBucketSource.state).logQueueSize()
            return .bucketDequeued(bucket: dequeuedBucket.bucket)
        case .workerBlocked:
            return .workerBlocked
        }
    }
}
