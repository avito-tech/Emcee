import AutomaticTermination
import DateProvider
import Deployer
import DistDeployer
import EventBus
import FileLock
import Foundation
import LocalHostDeterminer
import Logging
import Models
import PortDeterminer
import ProcessController
import QueueCommunication
import QueueServer
import RemotePortDeterminer
import RequestSender
import ScheduleStrategy
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator

public final class LocalQueueServerRunner {
    private let automaticTerminationController: AutomaticTerminationController
    private let deployQueue = DispatchQueue(label: "LocalQueueServerRunner.deployQueue", attributes: .concurrent)
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let pollPeriod: TimeInterval
    private let processControllerProvider: ProcessControllerProvider
    private let queueServer: QueueServer
    private let queueServerTerminationPolicy: AutomaticTerminationPolicy
    private let queueServerTerminationWaiter: QueueServerTerminationWaiter
    private let remotePortDeterminer: RemotePortDeterminer
    private let temporaryFolder: TemporaryFolder
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let workerDestinations: [DeploymentDestination]
    private let workerUtilizationStatusPoller: WorkerUtilizationStatusPoller

    public init(
        automaticTerminationController: AutomaticTerminationController,
        newWorkerRegistrationTimeAllowance: TimeInterval,
        pollPeriod: TimeInterval,
        processControllerProvider: ProcessControllerProvider,
        queueServer: QueueServer,
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        queueServerTerminationWaiter: QueueServerTerminationWaiter,
        remotePortDeterminer: RemotePortDeterminer,
        temporaryFolder: TemporaryFolder,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        workerDestinations: [DeploymentDestination],
        workerUtilizationStatusPoller: WorkerUtilizationStatusPoller
    ) {
        self.automaticTerminationController = automaticTerminationController
        self.newWorkerRegistrationTimeAllowance = newWorkerRegistrationTimeAllowance
        self.pollPeriod = pollPeriod
        self.processControllerProvider = processControllerProvider
        self.queueServer = queueServer
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.queueServerTerminationWaiter = queueServerTerminationWaiter
        self.remotePortDeterminer = remotePortDeterminer
        self.temporaryFolder = temporaryFolder
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.workerDestinations = workerDestinations
        self.workerUtilizationStatusPoller = workerUtilizationStatusPoller
    }
    
    public func start(emceeVersion: Version) throws {
        try startWorkers(
            emceeVersion: emceeVersion,
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
    
    private func startQueueServer(emceeVersion: Version) throws -> Models.Port {
        let lockToStartQueueServer = try FileLock.named("emcee_starting_queue_server_\(emceeVersion.value)")
        return try lockToStartQueueServer.whileLocked {
            try ensureQueueWithMatchingVersionIsNotRunning(version: emceeVersion)
            return try queueServer.start()
        }
    }
    
    private func ensureQueueWithMatchingVersionIsNotRunning(version: Version) throws {
        let portToQueueServerVersion = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: 10)
        
        try portToQueueServerVersion.forEach { (item: (key: Models.Port, value: Version)) in
            if item.value == version {
                throw LocalQueueServerError.sameVersionQueueIsAlreadyRunning(port: item.key, version: version)
            }
        }
    }
    
    private func startWorkers(emceeVersion: Version, port: Models.Port) throws {
        Logger.info("Deploying and starting workers in background")
        
        let remoteWorkersStarter = RemoteWorkersStarter(
            deploymentDestinations: workerDestinations,
            processControllerProvider: processControllerProvider,
            tempFolder: temporaryFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        try remoteWorkersStarter.deployAndStartWorkers(
            deployQueue: deployQueue,
            emceeVersion: emceeVersion,
            queueAddress: SocketAddress(host: LocalHostDeterminer.currentHostAddress, port: port)
        )
        deployQueue.async(flags: .barrier) {
            Logger.debug("Finished deploying workers")
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
