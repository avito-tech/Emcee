import ArgumentsParser
import AutomaticTermination
import DateProvider
import Deployer
import DistDeployer
import DistRunner
import EventBus
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import PluginManager
import PortDeterminer
import ResourceLocationResolver
import ScheduleStrategy
import TemporaryStuff
import Version
import UniqueIdentifierGenerator
import Utility
import SimulatorPool
import QueueServer
import RuntimeDump

final class DistRunTestsCommand: Command {
    let command = "distRunTests"
    let overview = "Starts a local queue, performs distributed UI tests run and writes report"

    private let analyticsConfigurationLocation: OptionArgument<String>
    private let destinationConfigurations: OptionArgument<String>
    private let destinations: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    private let fbxctest: OptionArgument<String>
    private let testRunnerMaximumSilenceDuration: OptionArgument<UInt>
    private let junit: OptionArgument<String>
    private let numberOfSimulators: OptionArgument<UInt>
    private let plugins: OptionArgument<[String]>
    private let runId: OptionArgument<String>
    private let simulatorLocalizationSettings: OptionArgument<String>
    private let singleTestTimeout: OptionArgument<UInt>
    private let testArgFile: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let trace: OptionArgument<String>
    private let watchdogSettings: OptionArgument<String>
    private let tempFolder: OptionArgument<String>

    private let resourceLocationResolver = ResourceLocationResolver()
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)

    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)

        analyticsConfigurationLocation = subparser.add(stringArgument: KnownStringArguments.analyticsConfiguration)
        destinationConfigurations = subparser.add(stringArgument: KnownStringArguments.destinationConfigurations)
        destinations = subparser.add(stringArgument: KnownStringArguments.destinations)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        testRunnerMaximumSilenceDuration = subparser.add(intArgument: KnownUIntArguments.testRunnerSilenceTimeout)
        junit = subparser.add(stringArgument: KnownStringArguments.junit)
        numberOfSimulators = subparser.add(intArgument: KnownUIntArguments.numberOfSimulators)
        plugins = subparser.add(multipleStringArgument: KnownStringArguments.plugin)
        runId = subparser.add(stringArgument: KnownStringArguments.runId)
        simulatorLocalizationSettings = subparser.add(stringArgument: KnownStringArguments.simulatorLocalizationSettings)
        singleTestTimeout = subparser.add(intArgument: KnownUIntArguments.singleTestTimeout)
        testArgFile = subparser.add(stringArgument: KnownStringArguments.testArgFile)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        trace = subparser.add(stringArgument: KnownStringArguments.trace)
        watchdogSettings = subparser.add(stringArgument: KnownStringArguments.watchdogSettings)
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let analyticsConfigurationLocation = AnalyticsConfigurationLocation(
            try ArgumentsReader.validateResourceLocationOrNil(arguments.get(self.analyticsConfigurationLocation), key: KnownStringArguments.analyticsConfiguration)
        )
        if let analyticsConfigurationLocation = analyticsConfigurationLocation {
            try AnalyticsConfigurator(resourceLocationResolver: resourceLocationResolver)
                .setup(analyticsConfigurationLocation: analyticsConfigurationLocation)
        }
        
        let auxiliaryResources = AuxiliaryResources(
            toolResources: ToolResources(
                simulatorControlTool: .fbsimctl(
                    FbsimctlLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl))
                ),
                testRunnerTool: .fbxctest(
                    FbxctestLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest))
                )
            ),
            plugins: try ArgumentsReader.validateResourceLocations(arguments.get(self.plugins) ?? [], key: KnownStringArguments.plugin).map({ PluginLocation($0) })
        )
        let reportOutput = ReportOutput(
            junit: arguments.get(self.junit),
            tracingReport: arguments.get(self.trace)
        )
        let simulatorSettings = try ArgumentsReader.simulatorSettings(
            localizationFile: arguments.get(self.simulatorLocalizationSettings),
            localizationKey: KnownStringArguments.simulatorLocalizationSettings,
            watchdogFile: arguments.get(self.watchdogSettings),
            watchdogKey: KnownStringArguments.watchdogSettings
        )
        let testTimeoutConfiguration = TestTimeoutConfiguration(
            singleTestMaximumDuration: TimeInterval(try ArgumentsReader.validateNotNil(arguments.get(self.singleTestTimeout), key: KnownUIntArguments.singleTestTimeout)),
            testRunnerMaximumSilenceDuration: TimeInterval((arguments.get(self.testRunnerMaximumSilenceDuration) ?? 0))
        )
        let testRunExecutionBehavior = TestRunExecutionBehavior(
            numberOfSimulators: try ArgumentsReader.validateNotNil(arguments.get(self.numberOfSimulators), key: KnownUIntArguments.numberOfSimulators)
        )
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }

        let deploymentDestinations = try ArgumentsReader.deploymentDestinations(arguments.get(self.destinations), key: KnownStringArguments.destinations)
        let destinationConfigurations = try ArgumentsReader.destinationConfigurations(arguments.get(self.destinationConfigurations), key: KnownStringArguments.destinationConfigurations)
        let runId = JobId(value: try ArgumentsReader.validateNotNil(arguments.get(self.runId), key: KnownStringArguments.runId))
        let tempFolder = try TemporaryFolder(
            containerPath: AbsolutePath(
                try ArgumentsReader.validateNotNil(
                    arguments.get(self.tempFolder), key: KnownStringArguments.tempFolder
                )
            )
        )
        let testArgFile = try ArgumentsReader.testArgFile(arguments.get(self.testArgFile), key: KnownStringArguments.testArgFile)
        let testDestinationConfigurations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)

        let validatorConfiguration = TestEntriesValidatorConfiguration(
            simulatorControlTool: auxiliaryResources.toolResources.simulatorControlTool,
            testDestination: testDestinationConfigurations.elementAtIndex(0, "First test destination").testDestination,
            testEntries: testArgFile.entries,
            testRunnerTool: auxiliaryResources.toolResources.testRunnerTool
        )
        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        let runtimeTestQuerier = RuntimeTestQuerierImpl(
            eventBus: eventBus,
            resourceLocationResolver: resourceLocationResolver,
            onDemandSimulatorPool: onDemandSimulatorPool,
            tempFolder: tempFolder
        )
        
        let testEntriesValidator = TestEntriesValidator(
            validatorConfiguration: validatorConfiguration,
            runtimeTestQuerier: runtimeTestQuerier
        )
        let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
            validatedEntries: try testEntriesValidator.validatedTestEntries(),
            testArgEntries: testArgFile.entries
        )
        
        let distRunConfiguration = DistRunConfiguration(
            analyticsConfigurationLocation: analyticsConfigurationLocation,
            runId: runId,
            reportOutput: reportOutput,
            destinations: deploymentDestinations,
            destinationConfigurations: destinationConfigurations,
            scheduleStrategyType: testArgFile.scheduleStrategy,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testRunExecutionBehavior: testRunExecutionBehavior,
            auxiliaryResources: auxiliaryResources,
            simulatorSettings: simulatorSettings,
            testEntryConfigurations: testEntryConfigurationGenerator.createTestEntryConfigurations(),
            testDestinationConfigurations: testDestinationConfigurations
        )
        try run(distRunConfiguration: distRunConfiguration, eventBus: eventBus, tempFolder: tempFolder)
    }
    
    func run(distRunConfiguration: DistRunConfiguration, eventBus: EventBus, tempFolder: TemporaryFolder) throws {
        Logger.verboseDebug("Using dist run configuration: \(distRunConfiguration)")
        let automaticTerminationController = AutomaticTerminationControllerFactory(
            automaticTerminationPolicy: .stayAlive
        ).createAutomaticTerminationController()
        let uniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
        let bucketSplitter = distRunConfiguration.scheduleStrategyType.bucketSplitter(
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        let requestSignature = RequestSignature(value: UUID().uuidString)
        let localPortDeterminer = LocalPortDeterminer(portRange: Ports.defaultQueuePortRange)
        let workerConfigurations = createWorkerConfigurations(
            distRunConfiguration: distRunConfiguration,
            requestSignature: requestSignature
        )
        let queueServer = QueueServerImpl(
            automaticTerminationController: automaticTerminationController,
            dateProvider: SystemDateProvider(),
            eventBus: eventBus,
            workerConfigurations: workerConfigurations,
            reportAliveInterval: distRunConfiguration.reportAliveInterval,
            checkAgainTimeInterval: distRunConfiguration.checkAgainTimeInterval,
            localPortDeterminer: localPortDeterminer,
            workerAlivenessPolicy: .workersTerminateWhenQueueIsDepleted,
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
        let workersStarter = RemoteWorkersStarter(
            deploymentId: distRunConfiguration.runId.value,
            emceeVersionProvider: localQueueVersionProvider,
            deploymentDestinations: distRunConfiguration.destinations,
            pluginLocations: distRunConfiguration.auxiliaryResources.plugins,
            analyticsConfigurationLocation: distRunConfiguration.analyticsConfigurationLocation,
            tempFolder: tempFolder
        )
        let queueServerTerminationWaiter = QueueServerTerminationWaiterImpl(
            pollInterval: 5.0,
            queueServerTerminationPolicy: .stayAlive // ?
        )
        let distRunner = DistRunner(
            automaticTerminationController: automaticTerminationController,
            bucketSplitter: bucketSplitter,
            distRunConfiguration: distRunConfiguration,
            queueServer: queueServer,
            queueServerTerminationWaiter: queueServerTerminationWaiter,
            workersStarter: workersStarter
        )
        let testingResults = try distRunner.run()
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: distRunConfiguration.reportOutput,
            testDestinationConfigurations: distRunConfiguration.testDestinationConfigurations
        ).generateOutput()
    }
    
    private func createWorkerConfigurations(
        distRunConfiguration: DistRunConfiguration,
        requestSignature: RequestSignature
    ) -> WorkerConfigurations {
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
