import BucketQueue
import Foundation
import Models
import RESTMethods
import RESTServer
import WorkerAlivenessTracker

public final class BucketResultRegistrar: RequestSignatureVerifyingRESTEndpoint {
    public typealias DecodedObjectType = PushBucketResultRequest
    public typealias ResponseType = BucketResultAcceptResponse

    private let bucketResultAccepter: BucketResultAccepter
    public let expectedRequestSignature: RequestSignature
    private let workerAlivenessTracker: WorkerAlivenessTracker

    public init(
        bucketResultAccepter: BucketResultAccepter,
        expectedRequestSignature: RequestSignature,
        workerAlivenessTracker: WorkerAlivenessTracker
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.expectedRequestSignature = expectedRequestSignature
        self.workerAlivenessTracker = workerAlivenessTracker
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
            workerAlivenessTracker.blockWorker(workerId: verifiedRequest.workerId)
            throw error
        }
    }
}
