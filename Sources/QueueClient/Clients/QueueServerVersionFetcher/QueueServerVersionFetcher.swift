import Dispatch
import Foundation
import Models
import RequestSender
import Version

public protocol QueueServerVersionFetcher {
    func fetchQueueServerVersion(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Version, RequestSenderError>) -> Void
    ) throws
}
