import Dispatch
import Foundation
import QueueModels
import Types

public protocol JobStateFetcher {
    func fetch(
        jobId: JobId,
        callbackQueue: DispatchQueue,
        completion: @escaping ((Either<JobState, Error>) -> ())
    )
}
