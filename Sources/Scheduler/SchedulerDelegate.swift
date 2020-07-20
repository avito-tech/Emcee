import Foundation
import Models
import QueueModels

public protocol SchedulerDelegate: class {
    func scheduler(
        _ sender: Scheduler,
        obtainedTestingResult testingResult: TestingResult,
        forBucket bucket: SchedulerBucket
    )
}
