import AutomaticTermination
import Models

public protocol QueueServerTerminationWaiter {
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
