import Dispatch
import Foundation
import QueueModels
import RESTMethods
import RequestSender
import Types

public final class QueueServerVersionFetcherImpl: QueueServerVersionFetcher {
    private let requestSender: RequestSender
    
    public init(requestSender: RequestSender) {
        self.requestSender = requestSender
    }
    
    public func fetchQueueServerVersion(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Version, Error>) -> Void
    ) {
        requestSender.sendRequestWithCallback(
            request: QueueVersionRequest(),
            callbackQueue: callbackQueue,
            logFailedRequest: false,
            callback: { (result: Either<QueueVersionResponse, RequestSenderError>) in
                completion(
                    result.mapResult {
                        switch $0 {
                        case .queueVersion(let version): return version
                        }
                    }
                )
            }
        )
    }
}
