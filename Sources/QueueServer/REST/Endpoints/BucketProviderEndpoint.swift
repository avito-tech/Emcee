import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import RESTMethods
import WorkerAlivenessTracker

public final class BucketProviderEndpoint: RESTEndpoint {
    private let bucketQueue: BucketQueue
    private let alivenessTracker: WorkerAlivenessTracker

    public init(bucketQueue: BucketQueue, alivenessTracker: WorkerAlivenessTracker) {
        self.bucketQueue = bucketQueue
        self.alivenessTracker = alivenessTracker
    }

    public func handle(decodedRequest: DequeueBucketRequest) throws -> DequeueBucketResponse {
        alivenessTracker.markWorkerAsAlive(workerId: decodedRequest.workerId)
        
        let dequeueResult = bucketQueue.dequeueBucket(
            requestId: decodedRequest.requestId,
            workerId: decodedRequest.workerId
        )
        
        switch dequeueResult {
        case .queueIsEmpty:
            return .queueIsEmpty
        case .checkAgainLater(let checkAfter):
            return .checkAgainLater(checkAfter: checkAfter)
        case .dequeuedBucket(let dequeuedBucket):
            alivenessTracker.didDequeueBucket(
                bucketId: dequeuedBucket.bucket.bucketId,
                workerId: decodedRequest.workerId
            )
            BucketQueueStateLogger(state: bucketQueue.state).logQueueSize()
            return .bucketDequeued(bucket: dequeuedBucket.bucket)
        case .workerBlocked:
            return .workerBlocked
        }
    }
}
