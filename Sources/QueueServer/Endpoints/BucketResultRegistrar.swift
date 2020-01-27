import BucketQueue
import Foundation
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class BucketResultRegistrar: PayloadSignatureVerifyingRESTEndpoint {
    public typealias DecodedObjectType = BucketResultPayload
    public typealias ResponseType = BucketResultAcceptResponse

    private let bucketResultAccepter: BucketResultAccepter
    public let expectedPayloadSignature: PayloadSignature
    private let workerAlivenessProvider: WorkerAlivenessProvider

    public init(
        bucketResultAccepter: BucketResultAccepter,
        expectedRequestSignature: PayloadSignature,
        workerAlivenessProvider: WorkerAlivenessProvider
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.expectedPayloadSignature = expectedRequestSignature
        self.workerAlivenessProvider = workerAlivenessProvider
    }

    public func handle(verifiedPayload: BucketResultPayload) throws -> BucketResultAcceptResponse {
        do {
            let acceptResult = try bucketResultAccepter.accept(
                testingResult: verifiedPayload.testingResult,
                requestId: verifiedPayload.requestId,
                workerId: verifiedPayload.workerId
            )
            return .bucketResultAccepted(bucketId: acceptResult.dequeuedBucket.enqueuedBucket.bucket.bucketId)
        } catch {
            workerAlivenessProvider.blockWorker(workerId: verifiedPayload.workerId)
            throw error
        }
    }
}
