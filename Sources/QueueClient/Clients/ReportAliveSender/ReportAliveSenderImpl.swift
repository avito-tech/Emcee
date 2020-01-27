import Dispatch
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
        requestSignature: PayloadSignature,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<ReportAliveResponse, Error>) -> ()
    ) {
        let request = ReportAliveRequest(
            payload: ReportAlivePayload(
                workerId: workerId,
                bucketIdsBeingProcessed: bucketIdsBeingProcessedProvider(),
                requestSignature: requestSignature
            )
        )

        requestSender.sendRequestWithCallback(
            request: request,
            callbackQueue: callbackQueue,
            callback: { (result: Either<ReportAliveResponse, RequestSenderError>) in
                do {
                    let response = try result.dematerialize()
                    completion(Either.success(response))
                } catch {
                    completion(Either.error(error))
                }
            }
        )
    }
}
