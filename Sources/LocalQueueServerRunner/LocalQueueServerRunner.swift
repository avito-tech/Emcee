import AutomaticTermination
import EventBus
import Logging
import Models
import PortDeterminer
import QueueServer
import ScheduleStrategy
import SynchronousWaiter
import Version

public final class LocalQueueServerRunner {
    private let eventBus: EventBus
    private let localPortDeterminer: LocalPortDeterminer
    private let localQueueVersionProvider: VersionProvider
    private let queueServerRunConfiguration: QueueServerRunConfiguration

    public init(
        eventBus: EventBus,
        localPortDeterminer: LocalPortDeterminer,
        localQueueVersionProvider: VersionProvider,
        queueServerRunConfiguration: QueueServerRunConfiguration)
    {
        self.eventBus = eventBus
        self.localPortDeterminer = localPortDeterminer
        self.localQueueVersionProvider = localQueueVersionProvider
        self.queueServerRunConfiguration = queueServerRunConfiguration
    }
    
    public func start() throws {
        let automaticTerminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        ).createAutomaticTerminationController()
        let queueServer = QueueServer(
            eventBus: eventBus,
            workerConfigurations: createWorkerConfigurations(),
            reportAliveInterval: queueServerRunConfiguration.reportAliveInterval,
            checkAgainTimeInterval: queueServerRunConfiguration.checkAgainTimeInterval,
            localPortDeterminer: localPortDeterminer,
            workerAlivenessPolicy: .workersStayAliveWhenQueueIsDepleted,
            bucketSplitter: queueServerRunConfiguration.remoteScheduleStrategyType.bucketSplitter(),
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(queueServerRunConfiguration.deploymentDestinationConfigurations.count),
                toolResources: queueServerRunConfiguration.auxiliaryResources.toolResources,
                simulatorSettings: queueServerRunConfiguration.simulatorSettings
            ),
            queueServerLock: AutomaticTerminationControllerAwareQueueServerLock(
                automaticTerminationController: automaticTerminationController
            ),
            queueVersionProvider: localQueueVersionProvider
        )
        _ = try queueServer.start()
        
        try waitForAutomaticTerminationControllerToTriggerStartOfTermination(automaticTerminationController)
        try allowQueueServerToFinishJobs(queueServer)
    }
    
    private func waitForAutomaticTerminationControllerToTriggerStartOfTermination(_ automaticTerminationController: AutomaticTerminationController) throws {
        try SynchronousWaiter.waitWhile(pollPeriod: 5.0, description: "Wait for automatic termination") {
            !automaticTerminationController.isTerminationAllowed
        }
    }
    
    private func allowQueueServerToFinishJobs(_ queueServer: QueueServer) throws {
        try queueServer.waitForBalancingQueueToDeplete()
    }
    
    private func createWorkerConfigurations() -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for deploymentDestinationConfiguration in queueServerRunConfiguration.deploymentDestinationConfigurations {
            configurations.add(
                workerId: deploymentDestinationConfiguration.destinationIdentifier,
                configuration: queueServerRunConfiguration.workerConfiguration(
                    deploymentDestinationConfiguration: deploymentDestinationConfiguration
                )
            )
        }
        return configurations
    }
}
