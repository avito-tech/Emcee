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
    private let logger: ContextualLogger

    public init(di: DI) throws {
        self.di = di
        self.logger = try di.get(ContextualLogger.self).forType(Self.self)
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

        try startQueueServer(
            emceeVersion: emceeVersion,
            queueServerConfiguration: queueServerConfiguration,
            workerDestinations: queueServerConfiguration.workerDeploymentDestinations
        )
    }
    
    private func startQueueServer(
        emceeVersion: Version,
        queueServerConfiguration: QueueServerConfiguration,
        workerDestinations: [DeploymentDestination]
    ) throws {
        di.set(
            PayloadSignature(value: try di.get(UniqueIdentifierGenerator.self).generate())
        )
        logger.debug("Generated payload signature: \(try di.get(PayloadSignature.self))")
        
        let automaticTerminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: queueServerConfiguration.queueServerTerminationPolicy
        ).createAutomaticTerminationController()
        
        let socketHost = LocalHostDeterminer.currentHostAddress
        let remotePortDeterminer = RemoteQueuePortScanner(
            host: socketHost,
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
            requestTimeout: 10,
            socketHost: socketHost,
            version: emceeVersion
        )
        let workerUtilizationStatusPoller = DefaultWorkerUtilizationStatusPoller(
            communicationService: queueCommunicationService,
            defaultDeployments: workerDestinations,
            emceeVersion: emceeVersion,
            logger: logger,
            globalMetricRecorder: try di.get(),
            queueHost: socketHost
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
        let queueServerPortProvider = SourcableQueueServerPortProvider()
        let workerConfigurations = try createWorkerConfigurations(
            queueServerConfiguration: queueServerConfiguration
        )
        
        let queueServer = QueueServerImpl(
            automaticTerminationController: automaticTerminationController,
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(queueServerConfiguration.workerSpecificConfigurations.count)
            ),
            checkAgainTimeInterval: queueServerConfiguration.checkAgainTimeInterval,
            dateProvider: try di.get(),
            deploymentDestinations: workerDestinations,
            emceeVersion: emceeVersion,
            localPortDeterminer: LocalPortDeterminer(portRange: EmceePorts.defaultQueuePortRange),
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
                workerPermissionProvider: workerUtilizationStatusPoller
            ),
            workerCapabilitiesStorage: WorkerCapabilitiesStorageImpl(),
            workerConfigurations: workerConfigurations,
            workerUtilizationStatusPoller: workerUtilizationStatusPoller,
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
            workerIds: workerDestinations.map { $0.workerId },
            workerUtilizationStatusPoller: workerUtilizationStatusPoller
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
