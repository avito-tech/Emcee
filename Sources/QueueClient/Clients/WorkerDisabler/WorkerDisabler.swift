import Dispatch
import Foundation
import Models

public protocol WorkerDisabler {
    func disableWorker(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    )
}
