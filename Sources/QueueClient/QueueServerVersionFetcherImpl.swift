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
    
    public func fetchQueueServerVersion(completion: @escaping (Either<Version, RequestSenderError>) -> Void) throws {
        try requestSender.sendRequestWithCallback(
            pathWithSlash: RESTMethod.queueVersion.withPrependingSlash,
            payload: QueueVersionRequest(),
            callback: { (result: Either<QueueVersionResponse, RequestSenderError>) in
                switch result {
                case .left(let queueVersionResponse):
                    switch queueVersionResponse {
                    case .queueVersion(let version):
                        completion(Either.success(version))
                    }
                case .right(let requestSenderError):
                    completion(Either.error(requestSenderError))
                }
            }
        )
    }
}
