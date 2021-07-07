import BucketQueue
import Foundation
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer

public final class BucketResultRegistrar: PayloadSignatureVerifyingRESTEndpoint {
    public typealias PayloadType = BucketResultPayload
    public typealias ResponseType = BucketResultAcceptResponse

    private let bucketResultAccepter: BucketResultAccepter
    public let expectedPayloadSignature: PayloadSignature
    public let path: RESTPath = RESTMethod.bucketResult
    public let requestIndicatesActivity = true

    public init(
        bucketResultAccepter: BucketResultAccepter,
        expectedPayloadSignature: PayloadSignature
    ) {
        self.bucketResultAccepter = bucketResultAccepter
        self.expectedPayloadSignature = expectedPayloadSignature
    }

    public func handle(verifiedPayload: BucketResultPayload) throws -> BucketResultAcceptResponse {
        let acceptResult = try bucketResultAccepter.accept(
            bucketId: verifiedPayload.bucketId,
            testingResult: verifiedPayload.testingResult,
            workerId: verifiedPayload.workerId
        )
        return .bucketResultAccepted(bucketId: acceptResult.dequeuedBucket.enqueuedBucket.bucket.bucketId)
    }
}
