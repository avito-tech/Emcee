import BucketQueue
import Foundation
import Models
import RESTMethods
import WorkerAlivenessTracker

public final class BucketResultRegistrar: RESTEndpoint {
    private let bucketResultAccepter: BucketResultAccepter
    private let workerAlivenessTracker: WorkerAlivenessTracker

    public init(
        bucketResultAccepter: BucketResultAccepter,
        workerAlivenessTracker: WorkerAlivenessTracker
        )
    {
        self.bucketResultAccepter = bucketResultAccepter
        self.workerAlivenessTracker = workerAlivenessTracker
    }

    public func handle(decodedRequest: PushBucketResultRequest) throws -> BucketResultAcceptResponse {
        do {
            let acceptResult = try bucketResultAccepter.accept(
                testingResult: decodedRequest.testingResult,
                requestId: decodedRequest.requestId,
                workerId: decodedRequest.workerId
            )
            return .bucketResultAccepted(bucketId: acceptResult.dequeuedBucket.enqueuedBucket.bucket.bucketId)
        } catch {
            workerAlivenessTracker.blockWorker(workerId: decodedRequest.workerId)
            throw error
        }
    }
}
