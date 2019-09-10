import Foundation
import Models
import RequestSender
import Version

public protocol QueueServerVersionFetcher {
    func fetchQueueServerVersion(completion: @escaping (Either<Version, RequestSenderError>) -> Void) throws
}
