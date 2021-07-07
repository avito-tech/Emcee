import BalancingBucketQueue
import BucketQueue
import Dispatch
import EventBus
import Foundation
import EmceeLogging
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import WorkerAlivenessProvider
import WorkerCapabilities

public final class BucketProviderEndpoint: PayloadSignatureVerifyingRESTEndpoint {
    public typealias PayloadType = DequeueBucketPayload
    public typealias ResponseType = DequeueBucketResponse

    private let checkAfter: TimeInterval
    private let dequeueableBucketSource: DequeueableBucketSource
    private let workerAlivenessProvider: WorkerAlivenessProvider
    public let expectedPayloadSignature: PayloadSignature
    public let path: RESTPath = RESTMethod.getBucket
    public let requestIndicatesActivity = false

    public init(
        checkAfter: TimeInterval,
        dequeueableBucketSource: DequeueableBucketSource,
        expectedPayloadSignature: PayloadSignature,
        workerAlivenessProvider: WorkerAlivenessProvider
    ) {
        self.checkAfter = checkAfter
        self.dequeueableBucketSource = dequeueableBucketSource
        self.expectedPayloadSignature = expectedPayloadSignature
        self.workerAlivenessProvider = workerAlivenessProvider
    }
    
    public func handle(verifiedPayload: DequeueBucketPayload) throws -> DequeueBucketResponse {
        guard workerAlivenessProvider.alivenessForWorker(workerId: verifiedPayload.workerId).registered else {
            throw WorkerIsNotRegisteredError(workerId: verifiedPayload.workerId)
        }
        
        guard workerAlivenessProvider.isWorkerEnabled(workerId: verifiedPayload.workerId) else {
            return .checkAgainLater(checkAfter: checkAfter)
        }
        
        if let dequeuedBucket = dequeueableBucketSource.dequeueBucket(
            workerCapabilities: verifiedPayload.workerCapabilities,
            workerId: verifiedPayload.workerId
        ) {
            workerAlivenessProvider.didDequeueBucket(
                bucketId: dequeuedBucket.enqueuedBucket.bucket.bucketId,
                workerId: verifiedPayload.workerId
            )
            return .bucketDequeued(
                bucket: dequeuedBucket.enqueuedBucket.bucket
            )
        }
        
        return .checkAgainLater(checkAfter: checkAfter)
    }
}

public struct WorkerIsNotRegisteredError: Error, CustomStringConvertible{
    public let workerId: WorkerId
    public var description: String { "Worker \(workerId) is not registered" }
}
