import Dispatch
import Foundation
import QueueModels
import ScheduleStrategy
import Types

public protocol TestScheduler {
    func scheduleTests(
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategy,
        similarlyConfiguredTestEntries: SimilarlyConfiguredTestEntries,
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Void, Error>) -> ()
    )
}
