import Dispatch
import Foundation
import QueueModels
import Types

public protocol QueueServerVersionFetcher {
    func fetchQueueServerVersion(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Version, Error>) -> Void
    )
}
