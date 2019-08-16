import Foundation
import Models
import RESTMethods
import RequestSender

public final class ReportAliveSenderImpl: ReportAliveSender {  
    private let requestSender: RequestSender

    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func reportAlive(
        bucketIdsBeingProcessedProvider: @autoclosure () -> (Set<BucketId>),
        workerId: WorkerId,
        requestSignature: RequestSignature,
        completion: @escaping (Either<ReportAliveResponse, RequestSenderError>) -> ()
    ) throws {
        try requestSender.sendRequestWithCallback(
            pathWithSlash: RESTMethod.reportAlive.withPrependingSlash,
            payload: ReportAliveRequest(
                workerId: workerId,
                bucketIdsBeingProcessed: bucketIdsBeingProcessedProvider(),
                requestSignature: requestSignature
            ),
            callback: completion
        )
    }
}
