import AutomaticTermination
import DateProvider
import EventBus
import Foundation
import Logging
import Models
import PortDeterminer
import QueueServer
import ScheduleStrategy
import SynchronousWaiter
import UniqueIdentifierGenerator
import Version

public final class LocalQueueServerRunner {
    private let queueServer: QueueServer
    private let automaticTerminationController: AutomaticTerminationController
    private let queueServerTerminationPolicy: AutomaticTerminationPolicy
    private let pollInterval: TimeInterval

    public init(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController,
        pollInterval: TimeInterval,
        queueServerTerminationPolicy: AutomaticTerminationPolicy
    ) {
        self.queueServer = queueServer
        self.automaticTerminationController = automaticTerminationController
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.pollInterval = pollInterval
    }
    
    public func start() throws {
        _ = try queueServer.start()
        try waitForAutomaticTerminationControllerToTriggerStartOfTermination(
            automaticTerminationController: automaticTerminationController,
            queueServer: queueServer
        )
        try waitForAllJobsToBeDeleted(
            queueServer: queueServer,
            timeout: queueServerTerminationPolicy.period
        )
    }
    
    private func waitForAutomaticTerminationControllerToTriggerStartOfTermination(
        automaticTerminationController: AutomaticTerminationController,
        queueServer: QueueServer) throws {
        try SynchronousWaiter.waitWhile(pollPeriod: pollPeriod, description: "Wait for automatic termination") {
            !automaticTerminationController.isTerminationAllowed || !queueServer.hasAnyAliveWorker
        }
    }
    
    private func waitForAllJobsToBeDeleted(queueServer: QueueServer, timeout: TimeInterval) throws {
        try SynchronousWaiter.waitWhile(pollPeriod: pollPeriod, timeout: timeout, description: "Wait for all jobs to be deleted") {
            !queueServer.ongoingJobIds.isEmpty || queueServer.isDepleted
        }
    }
    
}
