import ArgumentsParser
import Extensions
import Foundation
import LocalQueueServerRunner
import Logging
import Models
import PluginManager
import PortDeterminer
import ResourceLocationResolver
import Utility
import Version

final class StartQueueServerCommand: Command {
    let command = "startLocalQueueServer"
    let overview = "Starts queue server on local machine. This mode waits for jobs to be scheduled via REST API."
    
    private let deploymentDestinationConfigurations: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    private let fbxctest: OptionArgument<String>
    private let fbxctestSilenceTimeout: OptionArgument<UInt>
    private let fbxtestBundleReadyTimeout: OptionArgument<UInt>
    private let fbxtestCrashCheckTimeout: OptionArgument<UInt>
    private let fbxtestFastTimeout: OptionArgument<UInt>
    private let fbxtestRegularTimeout: OptionArgument<UInt>
    private let fbxtestSlowTimeout: OptionArgument<UInt>
    private let plugins: OptionArgument<[String]>
    private let remoteScheduleStrategy: OptionArgument<String>
    private let workerScheduleStrategy: OptionArgument<String>
    private let simulatorLocalizationSettings: OptionArgument<String>
    private let singleTestTimeout: OptionArgument<UInt>
    private let tempFolder: OptionArgument<String>
    private let watchdogSettings: OptionArgument<String>
    
    private let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
    private let resourceLocationResolver = ResourceLocationResolver()
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        
        deploymentDestinationConfigurations = subparser.add(stringArgument: KnownStringArguments.destinationConfigurations)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        fbxctestSilenceTimeout = subparser.add(intArgument: KnownUIntArguments.fbxctestSilenceTimeout)
        fbxtestBundleReadyTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestBundleReadyTimeout)
        fbxtestCrashCheckTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestCrashCheckTimeout)
        fbxtestFastTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestFastTimeout)
        fbxtestRegularTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestRegularTimeout)
        fbxtestSlowTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestSlowTimeout)
        plugins = subparser.add(multipleStringArgument: KnownStringArguments.plugin)
        remoteScheduleStrategy = subparser.add(stringArgument: KnownStringArguments.remoteScheduleStrategy)
        simulatorLocalizationSettings = subparser.add(stringArgument: KnownStringArguments.simulatorLocalizationSettings)
        singleTestTimeout = subparser.add(intArgument: KnownUIntArguments.singleTestTimeout)
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
        watchdogSettings = subparser.add(stringArgument: KnownStringArguments.watchdogSettings)
        workerScheduleStrategy = subparser.add(stringArgument: KnownStringArguments.scheduleStrategy)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let auxiliaryResources = AuxiliaryResources(
            toolResources: ToolResources(
                fbsimctl: FbsimctlLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)),
                fbxctest: FbxctestLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest))
            ),
            plugins: try ArgumentsReader.validateResourceLocations(arguments.get(self.plugins) ?? [], key: KnownStringArguments.plugin).map({ PluginLocation($0) })
        )
        let simulatorSettings = try ArgumentsReader.simulatorSettings(
            localizationFile: arguments.get(self.simulatorLocalizationSettings),
            localizationKey: KnownStringArguments.simulatorLocalizationSettings,
            watchdogFile: arguments.get(self.watchdogSettings),
            watchdogKey: KnownStringArguments.watchdogSettings
        )
        let testTimeoutConfiguration = TestTimeoutConfiguration(
            singleTestMaximumDuration: TimeInterval(try ArgumentsReader.validateNotNil(arguments.get(self.singleTestTimeout), key: KnownUIntArguments.singleTestTimeout)),
            fbxctestSilenceMaximumDuration: arguments.get(self.fbxctestSilenceTimeout).map { TimeInterval($0) },
            fbxtestFastTimeout: arguments.get(self.fbxtestFastTimeout).map { TimeInterval($0) },
            fbxtestRegularTimeout: arguments.get(self.fbxtestRegularTimeout).map { TimeInterval($0) },
            fbxtestSlowTimeout: arguments.get(self.fbxtestSlowTimeout).map { TimeInterval($0) },
            fbxtestBundleReadyTimeout: arguments.get(self.fbxtestBundleReadyTimeout).map { TimeInterval($0) },
            fbxtestCrashCheckTimeout: arguments.get(self.fbxtestCrashCheckTimeout).map { TimeInterval($0) }
        )
        
        let deploymentDestinationConfigurations = try ArgumentsReader.destinationConfigurations(arguments.get(self.deploymentDestinationConfigurations), key: KnownStringArguments.destinationConfigurations)
        let remoteScheduleStrategy = try ArgumentsReader.scheduleStrategy(arguments.get(self.remoteScheduleStrategy), key: KnownStringArguments.remoteScheduleStrategy)
        let workerScheduleStrategy = try ArgumentsReader.scheduleStrategy(arguments.get(self.workerScheduleStrategy), key: KnownStringArguments.scheduleStrategy)
        
        let queueServerRunConfiguration = QueueServerRunConfiguration(
            auxiliaryResources: auxiliaryResources,
            checkAgainTimeInterval: 30.0,
            deploymentDestinationConfigurations: deploymentDestinationConfigurations,
            queueServerTearDownPolicy: QueueServerTearDownPolicy.afterBeingIdle(period: 600),
            remoteScheduleStrategyType: remoteScheduleStrategy,
            reportAliveInterval: 30.0,
            simulatorSettings: simulatorSettings,
            testTimeoutConfiguration: testTimeoutConfiguration,
            workerScheduleStrategy: workerScheduleStrategy
        )
        
        try startQueueServer(queueServerRunConfiguration: queueServerRunConfiguration)
    }
    
    private func startQueueServer(queueServerRunConfiguration: QueueServerRunConfiguration) throws {
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: queueServerRunConfiguration.auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver,
            environment: [:]
        )
        defer { eventBus.tearDown() }
        
        let localQueueServerRunner = LocalQueueServerRunner(
            eventBus: eventBus,
            localPortDeterminer: LocalPortDeterminer(portRange: Ports.defaultQueuePortRange),
            localQueueVersionProvider: localQueueVersionProvider,
            queueServerRunConfiguration: queueServerRunConfiguration
        )
        try localQueueServerRunner.start()
    }
}
