import EventBus
import Foundation
import Models
import PortDeterminer
import QueueServer
import ResourceLocationResolver
import RuntimeDump
import ScheduleStrategy
import TempFolder

public final class DistRunner {    
    private let distRunConfiguration: DistRunConfiguration
    private let distRunDeployer: DistRunDeployer
    private let eventBus: EventBus
    private let localPortDeterminer: LocalPortDeterminer
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TempFolder
    
    public init(
        distRunConfiguration: DistRunConfiguration,
        eventBus: EventBus,
        localPortDeterminer: LocalPortDeterminer,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TempFolder
        )
    {
        self.distRunConfiguration = distRunConfiguration
        self.distRunDeployer = DistRunDeployer(distRunConfiguration: distRunConfiguration, tempFolder: tempFolder)
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
            localPortDeterminer: localPortDeterminer
        )
        queueServer.add(buckets: try prepareQueue())
        let port = try queueServer.start()
        try distRunDeployer.deployAndStartLaunchdJob(serverPort: port)
        return try queueServer.waitForQueueToFinish()
    }
    
    private func prepareQueue() throws -> [Bucket] {        
        let splitter = distRunConfiguration.remoteScheduleStrategyType.bucketSplitter()
        return splitter.generate(
            inputs: distRunConfiguration.testEntryConfigurations,
            splitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(distRunConfiguration.destinations.count),
                environment: distRunConfiguration.testRunExecutionBehavior.environment,
                toolResources: distRunConfiguration.auxiliaryResources.toolResources,
                simulatorSettings: distRunConfiguration.simulatorSettings
            )
        )
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
