import BalancingBucketQueue
import DistDeployer
import EventBus
import Foundation
import LocalHostDeterminer
import Models
import PortDeterminer
import QueueServer
import ResourceLocationResolver
import ScheduleStrategy
import TempFolder

public final class DistRunner {    
    private let distRunConfiguration: DistRunConfiguration
    private let eventBus: EventBus
    private let localPortDeterminer: LocalPortDeterminer
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TempFolder
    
    public init(
        distRunConfiguration: DistRunConfiguration,
        eventBus: EventBus,
        localPortDeterminer: LocalPortDeterminer,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TempFolder)
    {
        self.distRunConfiguration = distRunConfiguration
        self.eventBus = eventBus
        self.localPortDeterminer = localPortDeterminer
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
    }
    
    public func run() throws -> [TestingResult] {
        let queueServer = QueueServer(
            eventBus: eventBus,
            workerConfigurations: createWorkerConfigurations(),
            reportAliveInterval: distRunConfiguration.reportAliveInterval,
            numberOfRetries: distRunConfiguration.testRunExecutionBehavior.numberOfRetries,
            checkAgainTimeInterval: distRunConfiguration.checkAgainTimeInterval,
            localPortDeterminer: localPortDeterminer,
            nothingToDequeueBehavior: NothingToDequeueBehaviorWaitForAllQueuesToDeplete(checkAfter: distRunConfiguration.checkAgainTimeInterval),
            bucketSplitter: distRunConfiguration.remoteScheduleStrategyType.bucketSplitter(),
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(distRunConfiguration.destinations.count),
                toolResources: distRunConfiguration.auxiliaryResources.toolResources,
                simulatorSettings: distRunConfiguration.simulatorSettings
            )
        )
        queueServer.schedule(
            testEntryConfigurations: distRunConfiguration.testEntryConfigurations,
            jobId: distRunConfiguration.runId
        )
        let distRunDeployer = DistRunDeployer(
            deployerConfiguration: DeployerConfiguration.from(
                distRunConfiguration: distRunConfiguration,
                queueServerHost: LocalHostDeterminer.currentHostAddress,
                queueServerPort: try queueServer.start()
            ),
            tempFolder: tempFolder
        )
        try distRunDeployer.deployAndStartWorkersOnRemoteDestinations()
        return try queueServer.waitForJobToFinish(jobId: distRunConfiguration.runId)
    }
    
    private func createWorkerConfigurations() -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for destination in distRunConfiguration.destinations {
            configurations.add(
                workerId: destination.identifier,
                configuration: distRunConfiguration.workerConfiguration(destination: destination))
        }
        return configurations
    }
}
