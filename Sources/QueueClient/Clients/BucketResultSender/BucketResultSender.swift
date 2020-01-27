import Dispatch
import Foundation
import Models

public protocol BucketResultSender {
    func send(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId,
        requestSignature: PayloadSignature,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<BucketId, Error>) -> ()
    )
}
