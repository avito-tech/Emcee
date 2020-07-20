import Dispatch
import Foundation
import QueueModels
import Types

public protocol WorkerEnabler {
    func enableWorker(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    )
}
