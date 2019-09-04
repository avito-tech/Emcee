import AutomaticTermination
import DateProvider
import EventBus
import Foundation
import Logging
import Models
import PortDeterminer
import QueueServer
import RemotePortDeterminer
import RequestSender
import ScheduleStrategy
import SynchronousWaiter
import UniqueIdentifierGenerator
import Version

public final class LocalQueueServerRunner {
    private let queueServer: QueueServer
    private let automaticTerminationController: AutomaticTerminationController
    private let queueServerTerminationWaiter: QueueServerTerminationWaiter
    private let queueServerTerminationPolicy: AutomaticTerminationPolicy
    private let pollPeriod: TimeInterval
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let versionProvider: VersionProvider
    private let remotePortDeterminer: RemotePortDeterminer

    public init(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController,
        queueServerTerminationWaiter: QueueServerTerminationWaiter,
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        pollPeriod: TimeInterval,
        newWorkerRegistrationTimeAllowance: TimeInterval,
        versionProvider: VersionProvider,
        remotePortDeterminer: RemotePortDeterminer
    ) {
        self.queueServer = queueServer
        self.automaticTerminationController = automaticTerminationController
        self.queueServerTerminationWaiter = queueServerTerminationWaiter
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.pollPeriod = pollPeriod
        self.newWorkerRegistrationTimeAllowance = newWorkerRegistrationTimeAllowance
        self.versionProvider = versionProvider
        self.remotePortDeterminer = remotePortDeterminer
    }
    
    public func start() throws {
        try startQueueServer()
        
        try queueServerTerminationWaiter.waitForWorkerToAppear(
            queueServer: queueServer,
            timeout: newWorkerRegistrationTimeAllowance
        )
        try queueServerTerminationWaiter.waitForAllJobsToFinish(
            queueServer: queueServer,
            automaticTerminationController: automaticTerminationController
        )
        try waitForAllJobsToBeDeleted(
            queueServer: queueServer,
            timeout: queueServerTerminationPolicy.period
        )
    }
    
    private func startQueueServer() throws {
        let version = try versionProvider.version()
        
        let lockToStartQueueServer = try FileLock.named("emcee_starting_queue_server_\(version)")
        try lockToStartQueueServer.whileLocked {
            try ensureQueueWithMatchingVersionIsNotRunning(version: version)
            
            _ = try queueServer.start()
        }
    }
    
    private func ensureQueueWithMatchingVersionIsNotRunning(version: Version) throws {
        let portToQueueServerVersion = try remotePortDeterminer.queryPortAndQueueServerVersion(timeout: 10)
        
        try portToQueueServerVersion.forEach { (item: (key: Int, value: Version)) in
            if item.value == version {
                throw LocalQueueServerError.sameVersionQueueIsAlreadyRunning(port: item.key, version: version)
            }
        }
    }
    
    private func waitForAllJobsToBeDeleted(queueServer: QueueServer, timeout: TimeInterval) throws {
        try SynchronousWaiter.waitWhile(pollPeriod: pollPeriod, timeout: timeout, description: "Wait for all jobs to be deleted") {
            !queueServer.ongoingJobIds.isEmpty
        }
    }
}
