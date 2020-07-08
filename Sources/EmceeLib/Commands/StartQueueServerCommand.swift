import ArgLib
import AutomaticTermination
import DateProvider
import Deployer
import DistWorkerModels
import EmceeVersion
import Extensions
import Foundation
import LocalHostDeterminer
import LocalQueueServerRunner
import Logging
import LoggingSetup
import Models
import PluginManager
import PortDeterminer
import ProcessController
import QueueCommunication
import QueueServer
import RemotePortDeterminer
import RequestSender
import ResourceLocationResolver
import ScheduleStrategy
import TemporaryStuff
import UniqueIdentifierGenerator

public final class StartQueueServerCommand: Command {
    public let name = "startLocalQueueServer"
    public let description = "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API."
    public let arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asOptional,
        ArgumentDescriptions.queueServerRunConfigurationLocation.asRequired
    ]

    private let requestSenderProvider: RequestSenderProvider
    private let payloadSignature: PayloadSignature
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        requestSenderProvider: RequestSenderProvider,
        payloadSignature: PayloadSignature,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.requestSenderProvider = requestSenderProvider
        self.payloadSignature = payloadSignature
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func run(payload: CommandPayload) throws {
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        let queueServerRunConfiguration = try ArgumentsReader.queueServerRunConfiguration(
            location: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerRunConfigurationLocation.name),
            resourceLocationResolver: resourceLocationResolver
        )
        
        try AnalyticsSetup.setupAnalytics(analyticsConfiguration: queueServerRunConfiguration.analyticsConfiguration, emceeVersion: emceeVersion)
        
        try startQueueServer(
            emceeVersion: emceeVersion,
            queueServerRunConfiguration: queueServerRunConfiguration,
            workerDestinations: queueServerRunConfiguration.workerDeploymentDestinations
        )
    }
    
    private func startQueueServer(
        emceeVersion: Version,
        queueServerRunConfiguration: QueueServerRunConfiguration,
        workerDestinations: [DeploymentDestination]
    ) throws {
        Logger.info("Generated payload signature: \(payloadSignature)")
        
        let automaticTerminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        ).createAutomaticTerminationController()
        
        let socketHost = LocalHostDeterminer.currentHostAddress
        let remotePortDeterminer = RemoteQueuePortScanner(
            host: socketHost,
            portRange: Ports.defaultQueuePortRange,
            requestSenderProvider: requestSenderProvider
        )
        let queueCommunicationService = DefaultQueueCommunicationService(
            remoteQueueDetector: DefaultRemoteQueueDetector(
                emceeVersion: emceeVersion,
                remotePortDeterminer: remotePortDeterminer
            ),
            requestSenderProvider: requestSenderProvider,
            requestTimeout: 10,
            socketHost: socketHost,
            version: emceeVersion
        )
        let workerUtilizationStatusPoller = DefaultWorkerUtilizationStatusPoller(
            emceeVersion: emceeVersion,
            queueHost: socketHost,
            defaultDeployments: workerDestinations,
            communicationService: queueCommunicationService
        )
        
        let dateProvider = SystemDateProvider()
        
        let workersToUtilizeService = DefaultWorkersToUtilizeService(
            cache: DefaultWorkersMappingCache(cacheIvalidationTime: 300, dateProvider: dateProvider),
            calculator: DefaultWorkersToUtilizeCalculator(),
            communicationService: queueCommunicationService,
            portDeterminer: remotePortDeterminer
        )
        
        let queueServer = QueueServerImpl(
            automaticTerminationController: automaticTerminationController,
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(queueServerRunConfiguration.deploymentDestinationConfigurations.count)
            ),
            checkAgainTimeInterval: queueServerRunConfiguration.checkAgainTimeInterval,
            dateProvider: dateProvider,
            deploymentDestinations: workerDestinations,
            emceeVersion: emceeVersion,
            localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange),
            payloadSignature: payloadSignature,
            queueServerLock: AutomaticTerminationControllerAwareQueueServerLock(
                automaticTerminationController: automaticTerminationController
            ),
            requestSenderProvider: requestSenderProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerAlivenessPolicy: .workersStayAliveWhenQueueIsDepleted,
            workerConfigurations: createWorkerConfigurations(
                queueServerRunConfiguration: queueServerRunConfiguration
            ),
            workersToUtilizeService: workersToUtilizeService,
            workerUtilizationStatusPoller: workerUtilizationStatusPoller
        )
        let pollPeriod: TimeInterval = 5.0
        let queueServerTerminationWaiter = QueueServerTerminationWaiterImpl(
            pollInterval: pollPeriod,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        )
        
        let localQueueServerRunner = LocalQueueServerRunner(
            automaticTerminationController: automaticTerminationController,
            newWorkerRegistrationTimeAllowance: 360.0,
            pollPeriod: pollPeriod,
            processControllerProvider: processControllerProvider,
            queueServer: queueServer,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy,
            queueServerTerminationWaiter: queueServerTerminationWaiter,
            remotePortDeterminer: remotePortDeterminer,
            temporaryFolder: try TemporaryFolder(),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            workerDestinations: workerDestinations,
            workerUtilizationStatusPoller: workerUtilizationStatusPoller
        )
        try localQueueServerRunner.start(emceeVersion: emceeVersion)
    }
    
    private func createWorkerConfigurations(
        queueServerRunConfiguration: QueueServerRunConfiguration
    ) -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for deploymentDestinationConfiguration in queueServerRunConfiguration.deploymentDestinationConfigurations {
            configurations.add(
                workerId: deploymentDestinationConfiguration.destinationIdentifier,
                configuration: queueServerRunConfiguration.workerConfiguration(
                    deploymentDestinationConfiguration: deploymentDestinationConfiguration,
                    payloadSignature: payloadSignature
                )
            )
        }
        return configurations
    }
}
