import AutomaticTermination
import DateProvider
import DistDeployer
import EventBus
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
    private let temporaryFolder: TemporaryFolder
    private let workerDestinations: [DeploymentDestination]

    public init(
        queueServer: QueueServer,
        automaticTerminationController: AutomaticTerminationController,
        queueServerTerminationWaiter: QueueServerTerminationWaiter,
        queueServerTerminationPolicy: AutomaticTerminationPolicy,
        pollPeriod: TimeInterval,
        newWorkerRegistrationTimeAllowance: TimeInterval,
        versionProvider: VersionProvider,
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
        self.versionProvider = versionProvider
        self.remotePortDeterminer = remotePortDeterminer
        self.temporaryFolder = temporaryFolder
        self.workerDestinations = workerDestinations
    }
    
    public func start() throws {
        try startWorkers(
            port: try startQueueServer()
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
    
    private func startQueueServer() throws -> Int {
        let version = try versionProvider.version()
        
        let lockToStartQueueServer = try FileLock.named("emcee_starting_queue_server_\(version)")
        return try lockToStartQueueServer.whileLocked {
            try ensureQueueWithMatchingVersionIsNotRunning(version: version)
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
    
    private func startWorkers(port: Int) throws {
        Logger.info("Deploying and starting workers")
        
        let remoteWorkersStarter = RemoteWorkersStarter(
            emceeVersionProvider: versionProvider,
            deploymentDestinations: workerDestinations,
            tempFolder: temporaryFolder
        )
        try remoteWorkersStarter.deployAndStartWorkers(
            queueAddress: SocketAddress(host: LocalHostDeterminer.currentHostAddress, port: port)
        )
    }
    
    private func waitForAllJobsToBeDeleted(
        queueServer: QueueServer,
        timeout: TimeInterval
    ) throws {
        try SynchronousWaiter.waitWhile(pollPeriod: pollPeriod, timeout: timeout, description: "Wait for all jobs to be deleted") {
            !queueServer.ongoingJobIds.isEmpty
        }
    }
}
