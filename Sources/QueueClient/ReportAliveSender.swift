import Foundation
import Models
import RESTMethods
import RequestSender

public protocol ReportAliveSender {
    func reportAlive(
        bucketIdsBeingProcessedProvider: @autoclosure () -> (Set<BucketId>),
        workerId: WorkerId,
        requestSignature: RequestSignature,
        completion: @escaping (Either<ReportAliveResponse, RequestSenderError>) -> ()
    ) throws
}
