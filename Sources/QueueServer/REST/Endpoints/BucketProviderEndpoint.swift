import BalancingBucketQueue
import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import Metrics
import RESTMethods

public final class BucketProviderEndpoint: RESTEndpoint {
    private let dequeueableBucketSource: DequeueableBucketSource

    public init(dequeueableBucketSource: DequeueableBucketSource) {
        self.dequeueableBucketSource = dequeueableBucketSource
    }
    
    public func handle(decodedRequest: DequeueBucketRequest) throws -> DequeueBucketResponse {
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
            return .bucketDequeued(bucket: dequeuedBucket.enqueuedBucket.bucket)
        case .workerIsNotAlive:
            return .workerIsNotAlive
        case .workerIsBlocked:
            return .workerIsBlocked
        }
    }
}
