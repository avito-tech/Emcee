import AutomaticTermination
import FileLock
import Foundation
import LocalHostDeterminer
import EmceeLogging
import QueueCommunication
import QueueModels
import QueueServer
import RemotePortDeterminer
import SocketModels
import SynchronousWaiter

public final class LocalQueueServerRunner {
    private let automaticTerminationController: AutomaticTerminationController
    private let deployQueue: OperationQueue
    private let logger: ContextualLogger
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let pollPeriod: TimeInterval
    private let queueServer: QueueServer
    private let queueServerTerminationPolicy: AutomaticTerminationPolicy
    private let queueServerTerminationWaiter: QueueServerTerminationWaiter
    private let remotePortDeterminer: RemotePortDeterminer
    private let remoteWorkerStarterProvider: RemoteWorkerStarterProvider
    private let workerIds: [WorkerId]
    private let workerUtilizationStatusPoller: WorkerUtilizationStatusPoller
    
    public static func queueServerAddress(port: SocketModels.Port) -> SocketAddress {
        SocketAddress(host: LocalHostDeterminer.currentHostAddress, port: port)
    }

    public init(
        automaticTerminationController: AutomaticTerminationController,
        deployQueue: OperationQueue,
        logger: ContextualLogger,
        newWorkerRegistrationTimeAllowance: TimeInterval,
        pollPeriod: TimeInterval,
        queueServer: QueueServer,
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        queueServerTerminationWaiter: QueueServerTerminationWaiter,
        remotePortDeterminer: RemotePortDeterminer,
        remoteWorkerStarterProvider: RemoteWorkerStarterProvider,
        workerIds: [WorkerId],
        workerUtilizationStatusPoller: WorkerUtilizationStatusPoller
    ) {
        self.automaticTerminationController = automaticTerminationController
        self.deployQueue = deployQueue
        self.logger = logger
        self.newWorkerRegistrationTimeAllowance = newWorkerRegistrationTimeAllowance
        self.pollPeriod = pollPeriod
        self.queueServer = queueServer
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.queueServerTerminationWaiter = queueServerTerminationWaiter
        self.remotePortDeterminer = remotePortDeterminer
        self.remoteWorkerStarterProvider = remoteWorkerStarterProvider
        self.workerIds = workerIds
        self.workerUtilizationStatusPoller = workerUtilizationStatusPoller
    }
    
    public func start(emceeVersion: Version) throws {
        workerUtilizationStatusPoller.startPolling()
        
        try startWorkers(
            port: try startQueueServer(emceeVersion: emceeVersion)
        )
        
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
    
    private func startQueueServer(emceeVersion: Version) throws -> SocketModels.Port {
        let lockToStartQueueServer = try FileLock.named("emcee_starting_queue_server_\(emceeVersion.value)")
        return try lockToStartQueueServer.whileLocked {
            try ensureQueueWithMatchingVersionIsNotRunning(version: emceeVersion)
            return try queueServer.start()
        }
    }
    
    private func ensureQueueWithMatchingVersionIsNotRunning(version: Version) throws {
        let addressToQueueServerVersion = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: 10)
        
        try addressToQueueServerVersion.forEach { (item: (key: SocketAddress, value: Version)) in
            if item.value == version {
                throw LocalQueueServerError.sameVersionQueueIsAlreadyRunning(address: item.key, version: version)
            }
        }
    }
    
    private func startWorkers(port: SocketModels.Port) throws {
        logger.info("Deploying and starting workers in background")
        
        let dispatchGroup = DispatchGroup()
        
        for workerId in workerIds {
            dispatchGroup.enter()
            
            deployQueue.addOperation {
                do {
                    let remoteWorkerStarter = try self.remoteWorkerStarterProvider.remoteWorkerStarter(
                        workerId: workerId
                    )
                    try remoteWorkerStarter.deployAndStartWorker(
                        queueAddress: LocalQueueServerRunner.queueServerAddress(port: port)
                    )
                } catch {
                    self.logger.error("Failed to deploy to \(workerId): \(error)")
                }
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .global()) {
            self.logger.debug("Finished deploying workers")
        }
    }
    
    private func waitForAllJobsToBeDeleted(
        queueServer: QueueServer,
        timeout: TimeInterval
    ) throws {
        try SynchronousWaiter().waitWhile(pollPeriod: pollPeriod, timeout: timeout, description: "Wait for all jobs to be deleted") {
            !queueServer.ongoingJobIds.isEmpty
        }
    }
}
