import BalancingBucketQueue
import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import Models
import RESTMethods
import RESTServer

public final class BucketProviderEndpoint: RequestSignatureVerifyingRESTEndpoint {
    public typealias DecodedObjectType = DequeueBucketRequest
    public typealias ResponseType = DequeueBucketResponse

    private let dequeueableBucketSource: DequeueableBucketSource
    public let expectedRequestSignature: RequestSignature

    public init(
        dequeueableBucketSource: DequeueableBucketSource,
        expectedRequestSignature: RequestSignature
    ) {
        self.dequeueableBucketSource = dequeueableBucketSource
        self.expectedRequestSignature = expectedRequestSignature
    }
    
    public func handle(verifiedRequest: DequeueBucketRequest) throws -> DequeueBucketResponse {
        let dequeueResult = dequeueableBucketSource.dequeueBucket(
            requestId: verifiedRequest.requestId,
            workerId: verifiedRequest.workerId
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
