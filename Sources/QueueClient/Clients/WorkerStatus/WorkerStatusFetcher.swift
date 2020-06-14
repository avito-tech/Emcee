import Dispatch
import Foundation
import Models
import WorkerAlivenessModels

public protocol WorkerStatusFetcher {
    func fetch(
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<[WorkerId: WorkerAliveness], Error>) -> ()
    )
}
