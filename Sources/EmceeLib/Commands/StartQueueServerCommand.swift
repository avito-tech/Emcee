import ArgLib
import AutomaticTermination
import DateProvider
import Extensions
import Foundation
import LocalHostDeterminer
import LocalQueueServerRunner
import Logging
import LoggingSetup
import Models
import PluginManager
import PortDeterminer
import QueueServer
import RemotePortDeterminer
import RequestSender
import ResourceLocationResolver
import ScheduleStrategy
import TemporaryStuff
import UniqueIdentifierGenerator
import Version

public final class StartQueueServerCommand: Command {
    public let name = "startLocalQueueServer"
    public let description = "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API."
    public let arguments: Arguments = [
        ArgumentDescriptions.queueServerRunConfigurationLocation.asRequired
    ]
    
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    private let resourceLocationResolver: ResourceLocationResolver
    private let requestSignature = RequestSignature(value: UUID().uuidString)

    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerRunConfiguration = try ArgumentsReader.queueServerRunConfiguration(
            location: try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServerRunConfigurationLocation.name),
            resourceLocationResolver: resourceLocationResolver
        )
        
        try LoggingSetup.setupAnalytics(analyticsConfiguration: queueServerRunConfiguration.analyticsConfiguration)
        
        try startQueueServer(
            queueServerRunConfiguration: queueServerRunConfiguration,
            workerDestinations: queueServerRunConfiguration.workerDeploymentDestinations
        )
    }
    
    private func startQueueServer(
        queueServerRunConfiguration: QueueServerRunConfiguration,
        workerDestinations: [DeploymentDestination]
    ) throws {
        Logger.info("Generated request signature: \(requestSignature)")
        
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: queueServerRunConfiguration.auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }
        
        let automaticTerminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        ).createAutomaticTerminationController()
        let uniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
        let localPortDeterminer = LocalPortDeterminer(portRange: Ports.defaultQueuePortRange)
        let workerConfigurations = createWorkerConfigurations(
            queueServerRunConfiguration: queueServerRunConfiguration
        )
        let queueServer = QueueServerImpl(
            automaticTerminationController: automaticTerminationController,
            dateProvider: SystemDateProvider(),
            eventBus: eventBus,
            workerConfigurations: workerConfigurations,
            reportAliveInterval: queueServerRunConfiguration.reportAliveInterval,
            checkAgainTimeInterval: queueServerRunConfiguration.checkAgainTimeInterval,
            localPortDeterminer: localPortDeterminer,
            workerAlivenessPolicy: .workersStayAliveWhenQueueIsDepleted,
            bucketSplitInfo: BucketSplitInfo(
                numberOfWorkers: UInt(queueServerRunConfiguration.deploymentDestinationConfigurations.count),
                toolResources: queueServerRunConfiguration.auxiliaryResources.toolResources,
                simulatorSettings: queueServerRunConfiguration.simulatorSettings
            ),
            queueServerLock: AutomaticTerminationControllerAwareQueueServerLock(
                automaticTerminationController: automaticTerminationController
            ),
            queueVersionProvider: localQueueVersionProvider,
            requestSignature: requestSignature,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        let pollPeriod: TimeInterval = 5.0
        let queueServerTerminationWaiter = QueueServerTerminationWaiterImpl(
            pollInterval: pollPeriod,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        )
        
        let localQueueServerRunner = LocalQueueServerRunner(
            queueServer: queueServer,
            automaticTerminationController: automaticTerminationController,
            queueServerTerminationWaiter: queueServerTerminationWaiter,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy,
            pollPeriod: pollPeriod,
            newWorkerRegistrationTimeAllowance: 360.0,
            versionProvider: localQueueVersionProvider,
            remotePortDeterminer: RemoteQueuePortScanner(
                host: LocalHostDeterminer.currentHostAddress,
                portRange: Ports.defaultQueuePortRange,
                requestSenderProvider: DefaultRequestSenderProvider()
            ),
            temporaryFolder: try TemporaryFolder(),
            workerDestinations: workerDestinations
        )
        try localQueueServerRunner.start()
    }
    
    private func createWorkerConfigurations(queueServerRunConfiguration: QueueServerRunConfiguration) -> WorkerConfigurations {
        let configurations = WorkerConfigurations()
        for deploymentDestinationConfiguration in queueServerRunConfiguration.deploymentDestinationConfigurations {
            configurations.add(
                workerId: deploymentDestinationConfiguration.destinationIdentifier,
                configuration: queueServerRunConfiguration.workerConfiguration(
                    deploymentDestinationConfiguration: deploymentDestinationConfiguration,
                    requestSignature: requestSignature
                )
            )
        }
        return configurations
    }
}
