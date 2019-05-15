import Foundation
import Models

public protocol SchedulerDelegate: class {
    func scheduler(
        _ sender: Scheduler,
        obtainedTestingResult testingResult: TestingResult,
        forBucket bucket: SchedulerBucket
    )
}
