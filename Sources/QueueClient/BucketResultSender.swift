import Foundation
import Models
import RESTMethods
import RequestSender

public protocol BucketResultSender {
    func send(
        testingResult: TestingResult,
        requestId: RequestId,
        workerId: WorkerId,
        requestSignature: RequestSignature,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<BucketId, Error>) -> ()
    ) throws
}
