import AutomaticTermination
import DateProvider
import Deployer
import DistDeployer
import EventBus
import Foundation
import LocalHostDeterminer
import Logging
import Models
import PortDeterminer
import QueueServer
import ResourceLocationResolver
import ScheduleStrategy
import TemporaryStuff
import UniqueIdentifierGenerator
import Version

public final class DistRunner {
    private let automaticTerminationController: AutomaticTerminationController
    private let bucketSplitter: BucketSplitter
    private let distRunConfiguration: DistRunConfiguration
    private let queueServer: QueueServer
    private let queueServerTerminationWaiter: QueueServerTerminationWaiter
    private let workersStarter: RemoteWorkersStarter
    
    public init(
        automaticTerminationController: AutomaticTerminationController,
        bucketSplitter: BucketSplitter,
        distRunConfiguration: DistRunConfiguration,
        queueServer: QueueServer,
        queueServerTerminationWaiter: QueueServerTerminationWaiter,
        workersStarter: RemoteWorkersStarter
    ) {
        self.automaticTerminationController = automaticTerminationController
        self.bucketSplitter = bucketSplitter
        self.distRunConfiguration = distRunConfiguration
        self.queueServer = queueServer
        self.queueServerTerminationWaiter = queueServerTerminationWaiter
        self.workersStarter = workersStarter
    }
    
    public func run() throws -> [TestingResult] {
        queueServer.schedule(
            bucketSplitter: bucketSplitter,
            testEntryConfigurations: distRunConfiguration.testEntryConfigurations,
            prioritizedJob: PrioritizedJob(jobId: distRunConfiguration.runId, priority: Priority.medium)
        )
        let queuePort = try queueServer.start()
        let queueAddress = SocketAddress(
            host: LocalHostDeterminer.currentHostAddress,
            port: queuePort
        )
        try workersStarter.deployAndStartWorkers(
            queueAddress: queueAddress
        )
        return try queueServerTerminationWaiter.waitForJobToFinish(
            queueServer: queueServer,
            automaticTerminationController: automaticTerminationController,
            jobId: distRunConfiguration.runId
        ).testingResults
    }
    
}
