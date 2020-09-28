import Dispatch
import Foundation
import QueueModels
import Types

public protocol JobResultsFetcher {
    func fetch(
        jobId: JobId,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<JobResults, Error>) -> ()
    )
}
