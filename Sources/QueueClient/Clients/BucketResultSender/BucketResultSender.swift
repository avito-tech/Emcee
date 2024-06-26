import Dispatch
import Foundation
import QueueModels
import Types

public protocol BucketResultSender {
    func send(
        bucketId: BucketId,
        bucketResult: BucketResult,
        workerId: WorkerId,
        payloadSignature: PayloadSignature,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<BucketId, Error>) -> ()
    )
}
