import BucketQueue
import Foundation
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessProvider

public final class BucketResultRegistrar: RequestSignatureVerifyingRESTEndpoint {
    public typealias DecodedObjectType = PushBucketResultRequest
    public typealias ResponseType = BucketResultAcceptResponse

    private let bucketResultAccepter: BucketResultAccepter
    public let expectedRequestSignature: RequestSignature
    private let workerAlivenessProvider: WorkerAlivenessProvider

    public init(
        bucketResultAccepter: BucketResultAccepter,
        expectedRequestSignature: RequestSignature,
        workerAlivenessProvider: WorkerAlivenessProvider
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.expectedRequestSignature = expectedRequestSignature
        self.workerAlivenessProvider = workerAlivenessProvider
    }

    public func handle(verifiedRequest: PushBucketResultRequest) throws -> BucketResultAcceptResponse {
        do {
            let acceptResult = try bucketResultAccepter.accept(
                testingResult: verifiedRequest.testingResult,
                requestId: verifiedRequest.requestId,
                workerId: verifiedRequest.workerId
            )
            return .bucketResultAccepted(bucketId: acceptResult.dequeuedBucket.enqueuedBucket.bucket.bucketId)
        } catch {
            workerAlivenessProvider.blockWorker(workerId: verifiedRequest.workerId)
            throw error
        }
    }
}
