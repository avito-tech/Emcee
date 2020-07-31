import Dispatch
import Foundation
import QueueModels
import Types

public protocol WorkerKickstarter {
    func kickstart(
        workerId: WorkerId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<WorkerId, Error>) -> ()
    )
}
