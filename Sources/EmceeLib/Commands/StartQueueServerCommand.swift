import AutomaticTermination
import ArgumentsParser
import DateProvider
import Extensions
import Foundation
import LocalQueueServerRunner
import Logging
import LoggingSetup
import Models
import PluginManager
import PortDeterminer
import QueueServer
import ResourceLocationResolver
import ScheduleStrategy
import UniqueIdentifierGenerator
import Utility
import Version

final class StartQueueServerCommand: Command {
    let command = "startLocalQueueServer"
    let overview = "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API."
    
    private let queueServerRunConfigurationLocation: OptionArgument<String>
    
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    private let resourceLocationResolver = ResourceLocationResolver()
    private let requestSignature = RequestSignature(value: UUID().uuidString)
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        queueServerRunConfigurationLocation = subparser.add(stringArgument: KnownStringArguments.queueServerRunConfigurationLocation)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let queueServerRunConfiguration = try ArgumentsReader.queueServerRunConfiguration(
            arguments.get(self.queueServerRunConfigurationLocation),
            key: KnownStringArguments.queueServerRunConfigurationLocation,
            resourceLocationResolver: resourceLocationResolver
        )
        try LoggingSetup.setupAnalytics(analyticsConfiguration: queueServerRunConfiguration.analyticsConfiguration)
        
        try startQueueServer(queueServerRunConfiguration: queueServerRunConfiguration)
    }
    
    private func startQueueServer(queueServerRunConfiguration: QueueServerRunConfiguration) throws {
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
        let queueServerTerminationWaiter = QueueServerTerminationWaiter(
            pollInterval: 5.0,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
        )
        let localQueueServerRunner = LocalQueueServerRunner(
            queueServer: queueServer,
            automaticTerminationController: automaticTerminationController,
            queueServerTerminationWaiter: queueServerTerminationWaiter,
            queueServerTerminationPolicy: queueServerRunConfiguration.queueServerTerminationPolicy
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
