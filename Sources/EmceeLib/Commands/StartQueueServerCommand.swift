import ArgLib
import AutomaticTermination
import DI
import DateProvider
import Deployer
import DistWorkerModels
import EmceeVersion
import Foundation
import LocalHostDeterminer
import LocalQueueServerRunner
import EmceeLogging
import LoggingSetup
import Metrics
import MetricsExtensions
import PluginManager
import PortDeterminer
import ProcessController
import QueueCommunication
import QueueModels
import QueueServer
import QueueServerPortProvider
import RemotePortDeterminer
import RequestSender
import ResourceLocationResolver
import ScheduleStrategy
import Tmp
import UniqueIdentifierGenerator
import WorkerAlivenessProvider
import WorkerCapabilities

public final class StartQueueServerCommand: Command {
    public let name = "startLocalQueueServer"
    public let description = "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API."
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asOptional,
        ArgumentDescriptions.queueServerConfigurationLocation.asRequired
    ]

    private let deployQueue = OperationQueue.create(
        name: "StartQueueServerCommand.deployQueue",
        maxConcurrentOperationCount: 20,
        qualityOfService: .default
    )
    
    private let di: DI

    public init(di: DI) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        let queueServerConfiguration = try ArgumentsReader.queueServerConfiguration(
            location: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerConfigurationLocation.name),
            resourceLocationResolver: try di.get()
        )
        
        try di.get(GlobalMetricRecorder.self).set(analyticsConfiguration: queueServerConfiguration.globalAnalyticsConfiguration)
        if let kibanaConfiguration = queueServerConfiguration.globalAnalyticsConfiguration.kibanaConfiguration {
            try di.get(LoggingSetup.self).set(kibanaConfiguration: kibanaConfiguration)
        }
        
        di.set(
            try di.get(ContextualLogger.self).with(
                analyticsConfiguration: queueServerConfiguration.globalAnalyticsConfiguration
            )
        )
        di.set(
            BucketGeneratorImpl(uniqueIdentifierGenerator: try di.get()),
            for: BucketGenerator.self
        )

        try startQueueServer(
            emceeVersion: emceeVersion,
            queueServerConfiguration: queueServerConfiguration,
            workerDestinations: queueServerConfiguration.workerDeploymentDestinations,
            logger: try di.get()
        )
    }
    
    private func startQueueServer(
        emceeVersion: Version,
        queueServerConfiguration: QueueServerConfiguration,
        workerDestinations: [DeploymentDestination],
        logger: ContextualLogger
    ) throws {
        di.set(
            PayloadSignature(value: try di.get(UniqueIdentifierGenerator.self).generate())
        )
        logger.debug("Generated payload signature: \(try di.get(PayloadSignature.self))")
        
        let automaticTerminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: queueServerConfiguration.queueServerTerminationPolicy
        ).createAutomaticTerminationController()
        
        let currentHostName = LocalHostDeterminer.currentHostAddress
        let queueServerPortProvider = SourcableQueueServerPortProvider()
        
        let remotePortDeterminer = RemoteQueuePortScanner(
            hosts: queueServerConfiguration.queueServerDeploymentDestinations.map(\.host),
            logger: logger,
            portRange: EmceePorts.defaultQueuePortRange,
            requestSenderProvider: try di.get()
        )
        let queueCommunicationService = DefaultQueueCommunicationService(
            logger: logger,
            remoteQueueDetector: DefaultRemoteQueueDetector(
                emceeVersion: emceeVersion,
                logger: logger,
                remotePortDeterminer: remotePortDeterminer
            ),
            requestSenderProvider: try di.get(),
            requestTimeout: 10
        )
        let autoupdatingWorkerPermissionProvider = AutoupdatingWorkerPermissionProviderImpl(
            communicationService: queueCommunicationService,
            initialWorkerIds: Set(workerDestinations.map { $0.workerId }),
            emceeVersion: emceeVersion,
            logger: logger,
            globalMetricRecorder: try di.get(),
            queueHost: currentHostName,
            queueServerPortProvider: queueServerPortProvider
        )
        
        let workersToUtilizeService = DefaultWorkersToUtilizeService(
            cache: DefaultWorkersMappingCache(
                cacheIvalidationTime: 300,
                dateProvider: try di.get(),
                logger: logger
            ),
            calculator: DefaultWorkersToUtilizeCalculator(logger: logger),
            communicationService: queueCommunicationService,
            logger: logger,
            portDeterminer: remotePortDeterminer
        )
        
        let remoteWorkerStarterProvider = DefaultRemoteWorkerStarterProvider(
            emceeVersion: emceeVersion,
            logger: logger,
            processControllerProvider: try di.get(),
            tempFolder: try TemporaryFolder(),
            uniqueIdentifierGenerator: try di.get(),
            workerDeploymentDestinations: workerDestinations
        )
        let workerConfigurations = try createWorkerConfigurations(
            queueServerConfiguration: queueServerConfiguration
        )
        
        let queueServer = QueueServerImpl(
            automaticTerminationController: automaticTerminationController,
            autoupdatingWorkerPermissionProvider: autoupdatingWorkerPermissionProvider,
            bucketGenerator: try di.get(),
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(queueServerConfiguration.workerSpecificConfigurations.count),
                numberOfParallelBuckets: queueServerConfiguration.workerSpecificConfigurations.reduce(into: 0, { result, keyValue in
                    result += keyValue.value.numberOfSimulators
                })
            ),
            checkAgainTimeInterval: queueServerConfiguration.checkAgainTimeInterval,
            dateProvider: try di.get(),
            emceeVersion: emceeVersion,
            localPortDeterminer: LocalPortDeterminer(
                logger: logger,
                portRange: EmceePorts.defaultQueuePortRange
            ),
            logger: logger,
            globalMetricRecorder: try di.get(),
            specificMetricRecorderProvider: try di.get(),
            onDemandWorkerStarter: OnDemandWorkerStarterViaDeployer(
                queueServerPortProvider: queueServerPortProvider,
                remoteWorkerStarterProvider: remoteWorkerStarterProvider
            ),
            payloadSignature: try di.get(),
            queueServerLock: AutomaticTerminationControllerAwareQueueServerLock(
                automaticTerminationController: automaticTerminationController
            ),
            requestSenderProvider: try di.get(),
            uniqueIdentifierGenerator: try di.get(),
            workerAlivenessProvider: WorkerAlivenessProviderImpl(
                knownWorkerIds: workerConfigurations.workerIds,
                logger: logger,
                workerPermissionProvider: autoupdatingWorkerPermissionProvider
            ),
            workerCapabilitiesStorage: WorkerCapabilitiesStorageImpl(),
            workerConfigurations: workerConfigurations,
            workerIds: Set(workerDestinations.map { $0.workerId }),
            workersToUtilizeService: workersToUtilizeService
        )
        queueServerPortProvider.source = queueServer.queueServerPortProvider
        
        let pollPeriod: TimeInterval = 5.0
        let queueServerTerminationWaiter = QueueServerTerminationWaiterImpl(
            logger: logger,
            pollInterval: pollPeriod,
            queueServerTerminationPolicy: queueServerConfiguration.queueServerTerminationPolicy
        )
        
        let localQueueServerRunner = LocalQueueServerRunner(
            automaticTerminationController: automaticTerminationController,
            deployQueue: deployQueue,
            logger: logger,
            newWorkerRegistrationTimeAllowance: 360.0,
            pollPeriod: pollPeriod,
            queueServer: queueServer,
            queueServerTerminationPolicy: queueServerConfiguration.queueServerTerminationPolicy,
            queueServerTerminationWaiter: queueServerTerminationWaiter,
            remotePortDeterminer: remotePortDeterminer,
            remoteWorkerStarterProvider: remoteWorkerStarterProvider,
            workerIds: Set(workerDestinations.map { $0.workerId }),
            autoupdatingWorkerPermissionProvider: autoupdatingWorkerPermissionProvider
        )
        try localQueueServerRunner.start(emceeVersion: emceeVersion)
    }
    
    private func createWorkerConfigurations(
        queueServerConfiguration: QueueServerConfiguration
    ) throws -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for (workerId, workerSpecificConfiguration) in queueServerConfiguration.workerSpecificConfigurations {
            configurations.add(
                workerId: workerId,
                configuration: queueServerConfiguration.workerConfiguration(
                    workerSpecificConfiguration: workerSpecificConfiguration,
                    payloadSignature: try di.get()
                )
            )
        }
        return configurations
    }
}
