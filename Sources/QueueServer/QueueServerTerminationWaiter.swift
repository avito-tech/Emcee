import AutomaticTermination
import Foundation
import QueueModels

public protocol QueueServerTerminationWaiter {
    func waitForWorkerToAppear(
        queueServer: QueueServer,
        timeout: TimeInterval
    ) throws

    func waitForAllJobsToFinish(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController
    ) throws
    
    func waitForJobToFinish(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController,
        jobId: JobId
    ) throws -> JobResults
}
