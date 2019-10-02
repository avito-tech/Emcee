import Dispatch
import Foundation
import Models
import RESTMethods

public protocol ReportAliveSender {
    func reportAlive(
        bucketIdsBeingProcessedProvider: @autoclosure () -> (Set<BucketId>),
        workerId: WorkerId,
        requestSignature: RequestSignature,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<ReportAliveResponse, Error>) -> ()
    )
}
