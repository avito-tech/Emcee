import BalancingBucketQueue
import BucketQueue
import Dispatch
import EventBus
import Foundation
import Logging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer

public final class BucketProviderEndpoint: PayloadSignatureVerifyingRESTEndpoint {
    public typealias PayloadType = DequeueBucketPayload
    public typealias ResponseType = DequeueBucketResponse

    private let dequeueableBucketSource: DequeueableBucketSource
    public let expectedPayloadSignature: PayloadSignature
    public let path: RESTPath = RESTMethod.getBucket
    public let requestIndicatesActivity = false

    public init(
        dequeueableBucketSource: DequeueableBucketSource,
        expectedPayloadSignature: PayloadSignature
    ) {
        self.dequeueableBucketSource = dequeueableBucketSource
        self.expectedPayloadSignature = expectedPayloadSignature
    }
    
    public func handle(verifiedPayload: DequeueBucketPayload) throws -> DequeueBucketResponse {
        let dequeueResult = dequeueableBucketSource.dequeueBucket(
            requestId: verifiedPayload.requestId,
            workerCapabilities: verifiedPayload.workerCapabilities,
            workerId: verifiedPayload.workerId
        )
        
        switch dequeueResult {
        case .queueIsEmpty:
            return .queueIsEmpty
        case .checkAgainLater(let checkAfter):
            return .checkAgainLater(checkAfter: checkAfter)
        case .dequeuedBucket(let dequeuedBucket):
            return .bucketDequeued(bucket: dequeuedBucket.enqueuedBucket.bucket)
        case .workerIsNotRegistered:
            return .workerIsNotRegistered
        }
    }
}
