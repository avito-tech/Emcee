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
import Logging
import LoggingSetup
import Metrics
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
import TemporaryStuff
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

    public init(di: DI) {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        let queueServerConfiguration = try ArgumentsReader.queueServerConfiguration(
            location: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerConfigurationLocation.name),
            resourceLocationResolver: try di.get()
        )
        
        if let sentryConfiguration = queueServerConfiguration.analyticsConfiguration.sentryConfiguration {
            try AnalyticsSetup.setupSentry(sentryConfiguration: sentryConfiguration, emceeVersion: emceeVersion)
        }
        let metricRecorder: MutableMetricRecorder = try di.get()
        try metricRecorder.set(analyticsConfiguration: queueServerConfiguration.analyticsConfiguration)
        
        try startQueueServer(
            emceeVersion: emceeVersion,
            queueServerConfiguration: queueServerConfiguration,
            workerDestinations: queueServerConfiguration.workerDeploymentDestinations,
            metricRecorder: metricRecorder
        )
    }
    
    private func startQueueServer(
        emceeVersion: Version,
        queueServerConfiguration: QueueServerConfiguration,
        workerDestinations: [DeploymentDestination],
        metricRecorder: MetricRecorder
    ) throws {
        di.set(
            PayloadSignature(value: try di.get(UniqueIdentifierGenerator.self).generate())
        )
        Logger.info("Generated payload signature: \(try di.get(PayloadSignature.self))")
        
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
            remoteQueueDetector: DefaultRemoteQueueDetector(
                emceeVersion: emceeVersion,
                remotePortDeterminer: remotePortDeterminer
            ),
            requestSenderProvider: try di.get(),
            requestTimeout: 10,
            socketHost: socketHost,
            version: emceeVersion
        )
        let workerUtilizationStatusPoller = DefaultWorkerUtilizationStatusPoller(
            emceeVersion: emceeVersion,
            queueHost: socketHost,
            defaultDeployments: workerDestinations,
            communicationService: queueCommunicationService,
            metricRecorder: metricRecorder
        )
        
        let workersToUtilizeService = DefaultWorkersToUtilizeService(
            cache: DefaultWorkersMappingCache(cacheIvalidationTime: 300, dateProvider: try di.get()),
            calculator: DefaultWorkersToUtilizeCalculator(),
            communicationService: queueCommunicationService,
            portDeterminer: remotePortDeterminer
        )
        
        let remoteWorkerStarterProvider = DefaultRemoteWorkerStarterProvider(
            emceeVersion: emceeVersion,
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
            workersToUtilizeService: workersToUtilizeService,
            metricRecorder: metricRecorder
        )
        queueServerPortProvider.source = queueServer.queueServerPortProvider
        
        let pollPeriod: TimeInterval = 5.0
        let queueServerTerminationWaiter = QueueServerTerminationWaiterImpl(
            pollInterval: pollPeriod,
            queueServerTerminationPolicy: queueServerConfiguration.queueServerTerminationPolicy
        )
        
        let localQueueServerRunner = LocalQueueServerRunner(
            automaticTerminationController: automaticTerminationController,
            deployQueue: deployQueue,
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

private extension OperationQueue {
    static func create(
        name: String,
        maxConcurrentOperationCount: Int,
        qualityOfService: QualityOfService
    ) -> OperationQueue {
        let queue = OperationQueue()
        queue.name = name
        queue.maxConcurrentOperationCount = maxConcurrentOperationCount
        queue.qualityOfService = qualityOfService
        return queue
    }
}
