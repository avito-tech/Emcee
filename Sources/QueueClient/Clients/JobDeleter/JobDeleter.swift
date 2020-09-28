import Dispatch
import Foundation
import QueueModels
import Types

public protocol JobDeleter {
    func delete(
        jobId: JobId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<(), Error>) -> ()
    )
}
