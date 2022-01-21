import Dispatch
import Foundation
import LogStreamingModels
import QueueModels
import ScheduleStrategy
import Types

public protocol TestScheduler {
    func scheduleTests(
        clientDetails: ClientDetails,
        prioritizedJob: PrioritizedJob,
        scheduleStrategy: ScheduleStrategy,
        testEntryConfigurations: [TestEntryConfiguration],
        callbackQueue: DispatchQueue,
        completion: @escaping (Either<Void, Error>) -> ()
    )
}
