import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import RESTMethods

public final class BucketProviderEndpoint: RESTEndpoint {
    public typealias T = BucketFetchRequest
    
    private let bucketQueue: BucketQueue

    public init(bucketQueue: BucketQueue) {
        self.bucketQueue = bucketQueue
    }

    public func handle(decodedRequest: BucketFetchRequest) throws -> RESTResponse {
        let dequeueResult = bucketQueue.dequeueBucket(
            requestId: decodedRequest.requestId,
            workerId: decodedRequest.workerId)
        
        switch dequeueResult {
        case .queueIsEmpty:
            return .queueIsEmpty
        case .nothingToDequeueAtTheMoment:
            return .checkAgainLater(checkAfter: 30.0)
        case .dequeuedBucket(let dequeuedBucket):
            BucketQueueStateLogger(state: bucketQueue.state).logQueueSize()
            return .bucketDequeued(bucket: dequeuedBucket.bucket)
        case .workerBlocked:
            return .workerBlocked
        }
    }
}
