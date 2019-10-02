import Dispatch
import Foundation
import Models
import RESTMethods
import RequestSender
import Version

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
            pathWithSlash: RESTMethod.queueVersion.withPrependingSlash,
            payload: QueueVersionRequest(),
            callbackQueue: callbackQueue,
            callback: { (result: Either<QueueVersionResponse, RequestSenderError>) in
                do {
                    let response = try result.dematerialize()
                    switch response {
                    case .queueVersion(let version):
                        completion(Either.success(version))
                    }
                } catch {
                    completion(Either.error(error))
                }
            }
        )
    }
}
