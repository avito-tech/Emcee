import Dispatch
import Foundation
import Models
import Version

public protocol QueueServerVersionFetcher {
    func fetchQueueServerVersion(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Version, Error>) -> Void
    )
}
