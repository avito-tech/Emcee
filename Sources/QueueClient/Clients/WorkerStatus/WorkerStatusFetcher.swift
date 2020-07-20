import Dispatch
import Foundation
import QueueModels
import Types
import WorkerAlivenessModels

public protocol WorkerStatusFetcher {
    func fetch(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<[WorkerId: WorkerAliveness], Error>) -> ()
    )
}
