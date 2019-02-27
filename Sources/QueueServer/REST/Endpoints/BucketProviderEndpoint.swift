import BalancingBucketQueue
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
    private let dequeueableBucketSource: DequeueableBucketSource
    private let workerAlivenessTracker: WorkerAlivenessTracker

    public init(
        dequeueableBucketSource: DequeueableBucketSource,
        workerAlivenessTracker: WorkerAlivenessTracker
        )
    {
        self.dequeueableBucketSource = dequeueableBucketSource
        self.workerAlivenessTracker = workerAlivenessTracker
    }
    
    public func handle(decodedRequest: DequeueBucketRequest) throws -> DequeueBucketResponse {
        workerAlivenessTracker.markWorkerAsAlive(workerId: decodedRequest.workerId)
        
        let dequeueResult = dequeueableBucketSource.dequeueBucket(
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
            return .bucketDequeued(bucket: dequeuedBucket.enqueuedBucket.bucket)
        case .workerBlocked:
            return .workerBlocked
        }
    }
}
