import BucketQueue
import Foundation
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class BucketResultRegistrar: PayloadSignatureVerifyingRESTEndpoint {
    public typealias PayloadType = BucketResultPayload
    public typealias ResponseType = BucketResultAcceptResponse

    private let bucketResultAccepter: BucketResultAccepter
    public let expectedPayloadSignature: PayloadSignature
    private let workerAlivenessProvider: WorkerAlivenessProvider
    public let path: RESTPath = RESTMethod.bucketResult
    public let requestIndicatesActivity = true

    public init(
        bucketResultAccepter: BucketResultAccepter,
        expectedPayloadSignature: PayloadSignature,
        workerAlivenessProvider: WorkerAlivenessProvider
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.expectedPayloadSignature = expectedPayloadSignature
        self.workerAlivenessProvider = workerAlivenessProvider
    }

    public func handle(verifiedPayload: BucketResultPayload) throws -> BucketResultAcceptResponse {
        let acceptResult = try bucketResultAccepter.accept(
            testingResult: verifiedPayload.testingResult,
            requestId: verifiedPayload.requestId,
            workerId: verifiedPayload.workerId
        )
        return .bucketResultAccepted(bucketId: acceptResult.dequeuedBucket.enqueuedBucket.bucket.bucketId)
    }
}
