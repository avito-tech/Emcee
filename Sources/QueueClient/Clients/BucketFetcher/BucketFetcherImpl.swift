import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types
import WorkerCapabilitiesModels

public final class BucketFetcherImpl: BucketFetcher {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func fetch(
        payloadSignature: PayloadSignature,
        workerCapabilities: Set<WorkerCapability>,
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<BucketFetchResult, Error>) -> ()
    ) {
        let request = DequeueBucketRequest(
            payload: DequeueBucketPayload(
                payloadSignature: payloadSignature,
                workerCapabilities: workerCapabilities,
                workerId: workerId
            )
        )

        requestSender.sendRequestWithCallback(
            request: request,
            callbackQueue: callbackQueue,
            callback: { (response: Either<DequeueBucketResponse, RequestSenderError>) in
                do {
                    let value = try response.dematerialize()
                    switch value {
                    case .bucketDequeued(let bucket):
                        completion(.success(.bucket(bucket)))
                    case .checkAgainLater(let checkAfter):
                        completion(.success(.checkLater(checkAfter)))
                    }
                } catch {
                    completion(.error(error))
                }
            }
        )
    }
}
