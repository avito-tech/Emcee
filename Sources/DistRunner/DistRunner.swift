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
import TempFolder
import UniqueIdentifierGenerator
import Version

public final class DistRunner {    
    private let distRunConfiguration: DistRunConfiguration
    private let eventBus: EventBus
    private let localPortDeterminer: LocalPortDeterminer
    private let localQueueVersionProvider: VersionProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TempFolder
    private let requestSignature = RequestSignature(value: UUID().uuidString)
    private let uniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
    
    public init(
        distRunConfiguration: DistRunConfiguration,
        eventBus: EventBus,
        localPortDeterminer: LocalPortDeterminer,
        localQueueVersionProvider: VersionProvider,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TempFolder
    ) {
        self.distRunConfiguration = distRunConfiguration
        self.eventBus = eventBus
        self.localPortDeterminer = localPortDeterminer
        self.localQueueVersionProvider = localQueueVersionProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
    }
    
    public func run() throws -> [TestingResult] {
        let queueServer = QueueServer(
            automaticTerminationController: AutomaticTerminationControllerFactory(
                automaticTerminationPolicy: .stayAlive
            ).createAutomaticTerminationController(),
            dateProvider: SystemDateProvider(),
            eventBus: eventBus,
            workerConfigurations: createWorkerConfigurations(),
            reportAliveInterval: distRunConfiguration.reportAliveInterval,
            newWorkerRegistrationTimeAllowance: 360.0,
            checkAgainTimeInterval: distRunConfiguration.checkAgainTimeInterval,
            localPortDeterminer: localPortDeterminer,
            workerAlivenessPolicy: .workersTerminateWhenQueueIsDepleted,
            bucketSplitter: distRunConfiguration.remoteScheduleStrategyType.bucketSplitter(
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            ),
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(distRunConfiguration.destinations.count),
                toolResources: distRunConfiguration.auxiliaryResources.toolResources,
                simulatorSettings: distRunConfiguration.simulatorSettings
            ),
            queueServerLock: NeverLockableQueueServerLock(),
            queueVersionProvider: localQueueVersionProvider,
            requestSignature: requestSignature,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        queueServer.schedule(
            testEntryConfigurations: distRunConfiguration.testEntryConfigurations,
            prioritizedJob: PrioritizedJob(jobId: distRunConfiguration.runId, priority: Priority.medium)
        )
        let queuePort = try queueServer.start()
        
        let workersStarter = RemoteWorkersStarter(
            deploymentId: distRunConfiguration.runId.value,
            emceeVersionProvider: localQueueVersionProvider,
            deploymentDestinations: distRunConfiguration.destinations,
            pluginLocations: distRunConfiguration.auxiliaryResources.plugins,
            queueAddress: SocketAddress(
                host: LocalHostDeterminer.currentHostAddress,
                port: queuePort
            ),
            analyticsConfigurationLocation: distRunConfiguration.analyticsConfigurationLocation,
            tempFolder: tempFolder
        )
        try workersStarter.deployAndStartWorkers()
        
        return try queueServer.waitForJobToFinish(jobId: distRunConfiguration.runId).testingResults
    }
    
    private func createWorkerConfigurations() -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for destination in distRunConfiguration.destinations {
            configurations.add(
                workerId: WorkerId(value: destination.identifier),
                configuration: distRunConfiguration.workerConfiguration(
                    destination: destination,
                    requestSignature: requestSignature
                )
            )
        }
        return configurations
    }
}
