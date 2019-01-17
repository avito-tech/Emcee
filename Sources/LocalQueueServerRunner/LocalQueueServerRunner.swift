import BalancingBucketQueue
import EventBus
import Logging
import Models
import PortDeterminer
import QueueServer
import ScheduleStrategy
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
        let queueServer = QueueServer(
            eventBus: eventBus,
            workerConfigurations: createWorkerConfigurations(),
            reportAliveInterval: queueServerRunConfiguration.reportAliveInterval,
            checkAgainTimeInterval: queueServerRunConfiguration.checkAgainTimeInterval,
            localPortDeterminer: localPortDeterminer,
            nothingToDequeueBehavior: NothingToDequeueBehaviorCheckLater(
                checkAfter: queueServerRunConfiguration.checkAgainTimeInterval
            ),
            bucketSplitter: queueServerRunConfiguration.remoteScheduleStrategyType.bucketSplitter(),
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(queueServerRunConfiguration.deploymentDestinationConfigurations.count),
                toolResources: queueServerRunConfiguration.auxiliaryResources.toolResources,
                simulatorSettings: queueServerRunConfiguration.simulatorSettings
            ),
            queueVersionProvider: localQueueVersionProvider
        )
        let port = try queueServer.start()
        Logger.info("Started local queue server on port \(port)")
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
