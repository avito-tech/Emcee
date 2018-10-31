import ArgumentsParser
import Deployer
import DistRun
import Foundation
import Logging
import Models
import PluginManager
import ResourceLocationResolver
import ScheduleStrategy
import Utility

final class DistRunTestsCommand: Command {
    let command = "distRunTests"
    let overview = "Performs distributed UI tests run and writes report"
    
    private let additionalApp: OptionArgument<[String]>
    private let app: OptionArgument<String>
    private let destinationConfigurations: OptionArgument<String>
    private let destinations: OptionArgument<String>
    private let environment: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    private let fbxctest: OptionArgument<String>
    private let fbxctestSilenceTimeout: OptionArgument<UInt>
    private let fbxtestBundleReadyTimeout: OptionArgument<UInt>
    private let fbxtestCrashCheckTimeout: OptionArgument<UInt>
    private let fbxtestFastTimeout: OptionArgument<UInt>
    private let fbxtestRegularTimeout: OptionArgument<UInt>
    private let fbxtestSlowTimeout: OptionArgument<UInt>
    private let junit: OptionArgument<String>
    private let numberOfRetries: OptionArgument<UInt>
    private let numberOfSimulators: OptionArgument<UInt>
    private let onlyId: OptionArgument<[UInt]>
    private let onlyTest: OptionArgument<[String]>
    private let plugins: OptionArgument<[String]>
    private let remoteScheduleStrategy: OptionArgument<String>
    private let runId: OptionArgument<String>
    private let runner: OptionArgument<String>
    private let scheduleStrategy: OptionArgument<String>
    private let simulatorLocalizationSettings: OptionArgument<String>
    private let singleTestTimeout: OptionArgument<UInt>
    private let testDestinations: OptionArgument<String>
    private let trace: OptionArgument<String>
    private let watchdogSettings: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>
    
    private let resourceLocationResolver = ResourceLocationResolver()

    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        
        additionalApp = subparser.add(multipleStringArgument: KnownStringArguments.additionalApp)
        app = subparser.add(stringArgument: KnownStringArguments.app)
        destinationConfigurations = subparser.add(stringArgument: KnownStringArguments.destinationConfigurations)
        destinations = subparser.add(stringArgument: KnownStringArguments.destinations)
        environment = subparser.add(stringArgument: KnownStringArguments.environment)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        fbxctestSilenceTimeout = subparser.add(intArgument: KnownUIntArguments.fbxctestSilenceTimeout)
        fbxtestBundleReadyTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestBundleReadyTimeout)
        fbxtestCrashCheckTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestCrashCheckTimeout)
        fbxtestFastTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestFastTimeout)
        fbxtestRegularTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestRegularTimeout)
        fbxtestSlowTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestSlowTimeout)
        junit = subparser.add(stringArgument: KnownStringArguments.junit)
        numberOfRetries = subparser.add(intArgument: KnownUIntArguments.numberOfRetries)
        numberOfSimulators = subparser.add(intArgument: KnownUIntArguments.numberOfSimulators)
        onlyId = subparser.add(multipleIntArgument: KnownUIntArguments.onlyId)
        onlyTest = subparser.add(multipleStringArgument: KnownStringArguments.onlyTest)
        plugins = subparser.add(multipleStringArgument: KnownStringArguments.plugin)
        remoteScheduleStrategy = subparser.add(stringArgument: KnownStringArguments.remoteScheduleStrategy)
        runId = subparser.add(stringArgument: KnownStringArguments.runId)
        runner = subparser.add(stringArgument: KnownStringArguments.runner)
        scheduleStrategy = subparser.add(stringArgument: KnownStringArguments.scheduleStrategy)
        simulatorLocalizationSettings = subparser.add(stringArgument: KnownStringArguments.simulatorLocalizationSettings)
        singleTestTimeout = subparser.add(intArgument: KnownUIntArguments.singleTestTimeout)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        trace = subparser.add(stringArgument: KnownStringArguments.trace)
        watchdogSettings = subparser.add(stringArgument: KnownStringArguments.watchdogSettings)
        xctestBundle = subparser.add(stringArgument: KnownStringArguments.xctestBundle)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let additionalApp = try ArgumentsReader.validateFilesExist(arguments.get(self.additionalApp) ?? [], key: KnownStringArguments.additionalApp)
        let app = try ArgumentsReader.validateFileExists(arguments.get(self.app), key: KnownStringArguments.app)
        let deploymentDestinations = try ArgumentsReader.deploymentDestinations(arguments.get(self.destinations), key: KnownStringArguments.destinations)
        let destinationConfigurations = try ArgumentsReader.destinationConfigurations(arguments.get(self.destinationConfigurations), key: KnownStringArguments.destinationConfigurations)
        let environmentValues = try ArgumentsReader.environment(arguments.get(self.environment), key: KnownStringArguments.environment)
        let fbsimctl = try ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)
        let fbxctest = try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest)
        let junit = try ArgumentsReader.validateNotNil(arguments.get(self.junit), key: KnownStringArguments.junit)
        let numberOfRetries = try ArgumentsReader.validateNotNil(arguments.get(self.numberOfRetries), key: KnownUIntArguments.numberOfRetries)
        let numberOfSimulators = try ArgumentsReader.validateNotNil(arguments.get(self.numberOfSimulators), key: KnownUIntArguments.numberOfSimulators)
        let onlyId: [TestToRun] = (arguments.get(self.onlyId) ?? []).map { TestToRun.caseId($0) }
        let onlyTest: [TestToRun] = (arguments.get(self.onlyTest) ?? []).map { TestToRun.testName($0) }
        let plugins = try ArgumentsReader.validateResourceLocations(arguments.get(self.plugins) ?? [], key: KnownStringArguments.plugin)
        let remoteScheduleStrategy = try ArgumentsReader.scheduleStrategy(arguments.get(self.remoteScheduleStrategy), key: KnownStringArguments.remoteScheduleStrategy)
        let runId = try ArgumentsReader.validateNotNil(arguments.get(self.runId), key: KnownStringArguments.runId)
        let runner = try ArgumentsReader.validateNotNil(arguments.get(self.runner), key: KnownStringArguments.runner)
        let scheduleStrategy = try ArgumentsReader.scheduleStrategy(arguments.get(self.scheduleStrategy), key: KnownStringArguments.scheduleStrategy)
        let simulatorLocalizationSettings = try ArgumentsReader.validateNilOrFileExists(arguments.get(self.simulatorLocalizationSettings), key: KnownStringArguments.simulatorLocalizationSettings)
        let singleTestTimeout = try ArgumentsReader.validateNotNil(arguments.get(self.singleTestTimeout), key: KnownUIntArguments.singleTestTimeout)
        let fbxctestSilenceTimeout = arguments.get(self.fbxctestSilenceTimeout) ?? singleTestTimeout
        let fbxtestBundleReadyTimeout = arguments.get(self.fbxtestBundleReadyTimeout) ?? singleTestTimeout
        let fbxtestCrashCheckTimeout = arguments.get(self.fbxtestCrashCheckTimeout) ?? singleTestTimeout
        let fbxtestFastTimeout = arguments.get(self.fbxtestFastTimeout) ?? singleTestTimeout
        let fbxtestRegularTimeout = arguments.get(self.fbxtestRegularTimeout) ?? singleTestTimeout
        let fbxtestSlowTimeout = arguments.get(self.fbxtestSlowTimeout) ?? singleTestTimeout
        let testDestinations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        let trace = try ArgumentsReader.validateNotNil(arguments.get(self.trace), key: KnownStringArguments.trace)
        let watchdogSettings = try ArgumentsReader.validateNilOrFileExists(arguments.get(self.watchdogSettings), key: KnownStringArguments.watchdogSettings)
        let xctestBundle = try ArgumentsReader.validateFileExists(arguments.get(self.xctestBundle), key: KnownStringArguments.xctestBundle)
        
        let distRunConfiguration = DistRunConfiguration(
            runId: runId,
            reportOutput: ReportOutput(junit: junit, tracingReport: trace),
            destinations: deploymentDestinations,
            destinationConfigurations: destinationConfigurations,
            remoteScheduleStrategyType: remoteScheduleStrategy,
            testTimeoutConfiguration: TestTimeoutConfiguration(
                singleTestMaximumDuration: TimeInterval(singleTestTimeout),
                fbxctestSilenceMaximumDuration: TimeInterval(fbxctestSilenceTimeout),
                fbxtestFastTimeout: TimeInterval(fbxtestFastTimeout),
                fbxtestRegularTimeout: TimeInterval(fbxtestRegularTimeout),
                fbxtestSlowTimeout: TimeInterval(fbxtestSlowTimeout),
                fbxtestBundleReadyTimeout: TimeInterval(fbxtestBundleReadyTimeout),
                fbxtestCrashCheckTimeout: TimeInterval(fbxtestCrashCheckTimeout)),
            testExecutionBehavior: TestExecutionBehavior(
                numberOfRetries: numberOfRetries,
                numberOfSimulators: numberOfSimulators,
                environment: environmentValues,
                scheduleStrategy: scheduleStrategy),
            auxiliaryResources: AuxiliaryResources(
                toolResources: ToolResources(
                    fbsimctl: ResolvableResourceLocationImpl(resourceLocation: fbsimctl, resolver: resourceLocationResolver),
                    fbxctest: ResolvableResourceLocationImpl(resourceLocation: fbxctest, resolver: resourceLocationResolver)),
                plugins: plugins),
            buildArtifacts: BuildArtifacts(
                appBundle: app,
                runner: runner,
                xcTestBundle: xctestBundle,
                additionalApplicationBundles: additionalApp),
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: simulatorLocalizationSettings,
                watchdogSettings: watchdogSettings),
            testsToRun: onlyId + onlyTest,
            testDestinationConfigurations: testDestinations)
        try run(distRunConfiguration: distRunConfiguration)
    }
    
    func run(distRunConfiguration: DistRunConfiguration) throws {
        log("Using dist run configuration: \(distRunConfiguration)", color: .blue)
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: distRunConfiguration.auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver,
            environment: distRunConfiguration.testExecutionBehavior.environment)
        let distRunner = try DistRunner(eventBus: eventBus, distRunConfiguration: distRunConfiguration)
        let testingResults = try distRunner.run()
        eventBus.post(event: .tearDown)
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: distRunConfiguration.reportOutput,
            testDestinationConfigurations: distRunConfiguration.testDestinationConfigurations)
            .generateOutput()
    }
}
