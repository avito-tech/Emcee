import AutomaticTermination
import SynchronousWaiter
import Foundation
import Logging
import Models
import QueueModels

public final class QueueServerTerminationWaiterImpl: QueueServerTerminationWaiter {
    
    private let queueServerTerminationPolicy: AutomaticTerminationPolicy
    private let pollInterval: TimeInterval
    
    public init(
        pollInterval: TimeInterval,
        queueServerTerminationPolicy: AutomaticTerminationPolicy
    ) {
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.pollInterval = pollInterval
    }

    public func waitForWorkerToAppear(
        queueServer: QueueServer,
        timeout: TimeInterval
    ) throws {
        try SynchronousWaiter().waitWhile(
            pollPeriod: pollInterval,
            timeout: timeout,
            description: "Wait for first worker to appear"
        ) {
            queueServer.hasAnyAliveWorker == false
        }
    }
    
    public func waitForAllJobsToFinish(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController
    ) throws {
        try waitForAutomaticTerminationControllerToTriggerStartOfTermination(
            automaticTerminationController: automaticTerminationController,
            queueServer: queueServer
        )
        try waitForAllJobsToBeDeleted(
            queueServer: queueServer,
            timeout: queueServerTerminationPolicy.period
        )
    }
    
    public func waitForJobToFinish(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController,
        jobId: JobId
    ) throws -> JobResults {
        try waitForAllJobsToFinish(
            queueServer: queueServer,
            automaticTerminationController: automaticTerminationController
        )
        Logger.debug("Bucket queue has depleted")
        return try queueServer.queueResults(jobId: jobId)
    }
    
    private func waitForAutomaticTerminationControllerToTriggerStartOfTermination(
        automaticTerminationController: AutomaticTerminationController,
        queueServer: QueueServer
    ) throws {
        try SynchronousWaiter().waitWhile(
            pollPeriod: pollInterval,
            description: "Automatic termination"
        ) {
            queueServer.hasAnyAliveWorker && !automaticTerminationController.isTerminationAllowed
        }
    }
    
    private func waitForAllJobsToBeDeleted(
        queueServer: QueueServer,
        timeout: TimeInterval
    ) throws {
        try SynchronousWaiter().waitWhile(
            pollPeriod: pollInterval,
            timeout: timeout,
            description: "Wait for all jobs to be deleted"
        ) {
            queueServer.hasAnyAliveWorker && !queueServer.isDepleted
        }
    }
}
