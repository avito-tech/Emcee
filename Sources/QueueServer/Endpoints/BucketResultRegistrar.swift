import BucketQueue
import Foundation
import QueueModels
import RESTInterfaces
import RESTMethods
import RESTServer

public final class BucketResultRegistrar: PayloadSignatureVerifyingRESTEndpoint {
    public typealias PayloadType = BucketResultPayload
    public typealias ResponseType = BucketResultAcceptResponse

    private let bucketResultAcceptor: BucketResultAcceptor
    public let expectedPayloadSignature: PayloadSignature
    public let path: RESTPath = RESTMethod.bucketResult
    public let requestIndicatesActivity = true

    public init(
        bucketResultAcceptor: BucketResultAcceptor,
        expectedPayloadSignature: PayloadSignature
    ) {
        self.bucketResultAcceptor = bucketResultAcceptor
        self.expectedPayloadSignature = expectedPayloadSignature
    }

    public func handle(verifiedPayload: BucketResultPayload) throws -> BucketResultAcceptResponse {
        let acceptResult = try bucketResultAcceptor.accept(
            bucketId: verifiedPayload.bucketId,
            bucketResult: verifiedPayload.bucketResult,
            workerId: verifiedPayload.workerId
        )
        return .bucketResultAccepted(
            bucketId: acceptResult.dequeuedBucket.enqueuedBucket.bucket.bucketId
        )
    }
}
