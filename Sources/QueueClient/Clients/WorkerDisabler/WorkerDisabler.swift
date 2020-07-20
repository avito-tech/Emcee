import Dispatch
import Foundation
import QueueModels
import Types

public protocol WorkerDisabler {
    func disableWorker(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    )
}
