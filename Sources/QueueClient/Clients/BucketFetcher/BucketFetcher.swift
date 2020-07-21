import Dispatch
import Foundation
import QueueModels
import Types
import WorkerCapabilitiesModels

public protocol BucketFetcher {
    
    /// Request id is a unique request identifier that could be used to retry bucket fetch in case if
    /// request has failed. Server is expected to return the same bucket if request id + worker id pair
    /// match for sequential requests.
    /// Apple's guide on handling Handling "The network connection was lost" errors:
    /// https://developer.apple.com/library/archive/qa/qa1941/_index.html
    func fetch(
        payloadSignature: PayloadSignature,
        requestId: RequestId,
        workerCapabilities: Set<WorkerCapability>,
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<BucketFetchResult, Error>) -> ()
    )
}
