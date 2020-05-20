import Dispatch
import Foundation
import Models

public protocol WorkerEnabler {
    func enableWorker(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    )
}
