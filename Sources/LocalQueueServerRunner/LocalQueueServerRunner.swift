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
import QueueServer
import RemotePortDeterminer
import RequestSender
import ScheduleStrategy
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator

public final class LocalQueueServerRunner {
    private let queueServer: QueueServer
    private let automaticTerminationController: AutomaticTerminationController
    private let queueServerTerminationWaiter: QueueServerTerminationWaiter
    private let queueServerTerminationPolicy: AutomaticTerminationPolicy
    private let pollPeriod: TimeInterval
    private let newWorkerRegistrationTimeAllowance: TimeInterval
    private let remotePortDeterminer: RemotePortDeterminer
    private let temporaryFolder: TemporaryFolder
    private let workerDestinations: [DeploymentDestination]
    private let deployQueue = DispatchQueue(label: "LocalQueueServerRunner.deployQueue", attributes: .concurrent)
    

    public init(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController,
        queueServerTerminationWaiter: QueueServerTerminationWaiter,
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        pollPeriod: TimeInterval,
        newWorkerRegistrationTimeAllowance: TimeInterval,
        remotePortDeterminer: RemotePortDeterminer,
        temporaryFolder: TemporaryFolder,
        workerDestinations: [DeploymentDestination]
    ) {
        self.queueServer = queueServer
        self.automaticTerminationController = automaticTerminationController
        self.queueServerTerminationWaiter = queueServerTerminationWaiter
        self.queueServerTerminationPolicy = queueServerTerminationPolicy
        self.pollPeriod = pollPeriod
        self.newWorkerRegistrationTimeAllowance = newWorkerRegistrationTimeAllowance
        self.remotePortDeterminer = remotePortDeterminer
        self.temporaryFolder = temporaryFolder
        self.workerDestinations = workerDestinations
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
    
    private func startQueueServer(emceeVersion: Version) throws -> Int {
        let lockToStartQueueServer = try FileLock.named("emcee_starting_queue_server_\(emceeVersion.value)")
        return try lockToStartQueueServer.whileLocked {
            try ensureQueueWithMatchingVersionIsNotRunning(version: emceeVersion)
            return try queueServer.start()
        }
    }
    
    private func ensureQueueWithMatchingVersionIsNotRunning(version: Version) throws {
        let portToQueueServerVersion = remotePortDeterminer.queryPortAndQueueServerVersion(timeout: 10)
        
        try portToQueueServerVersion.forEach { (item: (key: Int, value: Version)) in
            if item.value == version {
                throw LocalQueueServerError.sameVersionQueueIsAlreadyRunning(port: item.key, version: version)
            }
        }
    }
    
    private func startWorkers(emceeVersion: Version, port: Int) throws {
        Logger.info("Deploying and starting workers in background")
        
        let remoteWorkersStarter = RemoteWorkersStarter(
            deploymentDestinations: workerDestinations,
            tempFolder: temporaryFolder
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
