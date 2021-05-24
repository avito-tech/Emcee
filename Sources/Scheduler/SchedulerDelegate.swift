import Foundation
import QueueModels

public protocol SchedulerDelegate: AnyObject {
    func scheduler(
        _ sender: Scheduler,
        obtainedTestingResult testingResult: TestingResult,
        forBucket bucket: SchedulerBucket
    )
}
