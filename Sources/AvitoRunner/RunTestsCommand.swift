import ArgumentsParser
import ChromeTracing
import EventBus
import Extensions
import Foundation
import JunitReporting
import Logging
import ModelFactories
import Models
import PluginManager
import Runner
import RuntimeDump
import ScheduleStrategy
import Scheduler
import SimulatorPool
import TempFolder
import Utility

final class RunTestsCommand: Command {
    let command = "runTests"
    let overview = "Runs UI tests and writes report"
    
    private let additionalApp: OptionArgument<[String]>
    private let app: OptionArgument<String>
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
    private let oslogPath: OptionArgument<String>
    private let plugins: OptionArgument<[String]>
    private let runner: OptionArgument<String>
    private let scheduleStrategy: OptionArgument<String>
    private let simulatorLocalizationSettings: OptionArgument<String>
    private let singleTestTimeout: OptionArgument<UInt>
    private let tempFolder: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let testLogPath: OptionArgument<String>
    private let trace: OptionArgument<String>
    private let videoPath: OptionArgument<String>
    private let watchdogSettings: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        
        additionalApp = subparser.add(multipleStringArgument: KnownStringArguments.additionalApp)
        app = subparser.add(stringArgument: KnownStringArguments.app)
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
        oslogPath = subparser.add(stringArgument: KnownStringArguments.oslogPath)
        plugins = subparser.add(multipleStringArgument: KnownStringArguments.plugin)
        runner = subparser.add(stringArgument: KnownStringArguments.runner)
        scheduleStrategy = subparser.add(stringArgument: KnownStringArguments.scheduleStrategy)
        simulatorLocalizationSettings = subparser.add(stringArgument: KnownStringArguments.simulatorLocalizationSettings)
        singleTestTimeout = subparser.add(intArgument: KnownUIntArguments.singleTestTimeout)
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        testLogPath = subparser.add(stringArgument: KnownStringArguments.testLogPath)
        trace = subparser.add(stringArgument: KnownStringArguments.trace)
        videoPath = subparser.add(stringArgument: KnownStringArguments.videoPath)
        watchdogSettings = subparser.add(stringArgument: KnownStringArguments.watchdogSettings)
        xctestBundle = subparser.add(stringArgument: KnownStringArguments.xctestBundle)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let additionalApp = try ArgumentsReader.validateFilesExist(arguments.get(self.additionalApp) ?? [], key: KnownStringArguments.additionalApp)
        let app = try ArgumentsReader.validateFileExists(arguments.get(self.app), key: KnownStringArguments.app)
        let environmentValues = try ArgumentsReader.environment(arguments.get(self.environment), key: KnownStringArguments.environment)
        let fbsimctl = try ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)
        let fbxctest = try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest)
        let junit = try ArgumentsReader.validateNotNil(arguments.get(self.junit), key: KnownStringArguments.junit)
        let numberOfRetries = try ArgumentsReader.validateNotNil(arguments.get(self.numberOfRetries), key: KnownUIntArguments.numberOfRetries)
        let numberOfSimulators = try ArgumentsReader.validateNotNil(arguments.get(self.numberOfSimulators), key: KnownUIntArguments.numberOfSimulators)
        let onlyId: [TestToRun] = (arguments.get(self.onlyId) ?? []).map { TestToRun.caseId($0) }
        let onlyTest: [TestToRun] = (arguments.get(self.onlyTest) ?? []).map { TestToRun.testName($0) }
        let oslogPath = arguments.get(self.oslogPath)
        let plugins = try ArgumentsReader.validateResourceLocations(arguments.get(self.plugins) ?? [], key: KnownStringArguments.plugin)
        let runner = try ArgumentsReader.validateNotNil(arguments.get(self.runner), key: KnownStringArguments.runner)
        let scheduleStrategy = try ArgumentsReader.scheduleStrategy(arguments.get(self.scheduleStrategy), key: KnownStringArguments.scheduleStrategy)
        let simulatorLocalizationSettings = try ArgumentsReader.validateNilOrFileExists(arguments.get(self.simulatorLocalizationSettings), key: KnownStringArguments.simulatorLocalizationSettings)
        let singleTestTimeout = try ArgumentsReader.validateNotNil(arguments.get(self.singleTestTimeout), key: KnownUIntArguments.singleTestTimeout)
        let fbxctestSilenceTimeout = arguments.get(self.fbxctestSilenceTimeout) ?? singleTestTimeout
        let fbxtestFastTimeout = arguments.get(self.fbxtestFastTimeout) ?? singleTestTimeout
        let fbxtestRegularTimeout = arguments.get(self.fbxtestRegularTimeout) ?? singleTestTimeout
        let fbxtestSlowTimeout = arguments.get(self.fbxtestSlowTimeout) ?? singleTestTimeout
        let fbxtestBundleReadyTimeout = arguments.get(self.fbxtestBundleReadyTimeout) ?? singleTestTimeout
        let fbxtestCrashCheckTimeout = arguments.get(self.fbxtestCrashCheckTimeout) ?? singleTestTimeout
        let tempFolder = try TempFolder.with(stringPath: try ArgumentsReader.validateNotNil(arguments.get(self.tempFolder), key: KnownStringArguments.tempFolder))
        let testDestinations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        let testLogPath = arguments.get(self.testLogPath)
        let trace = try ArgumentsReader.validateNotNil(arguments.get(self.trace), key: KnownStringArguments.trace)
        let videoPath = arguments.get(self.videoPath)
        let watchdogSettings = try ArgumentsReader.validateNilOrFileExists(arguments.get(self.watchdogSettings), key: KnownStringArguments.watchdogSettings)
        let xctestBundle = try ArgumentsReader.validateFileExists(arguments.get(self.xctestBundle), key: KnownStringArguments.xctestBundle)

        let configuration = try LocalTestRunConfiguration(
            reportOutput: ReportOutput(junit: junit, tracingReport: trace),
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
            auxiliaryPaths: AuxiliaryPaths(
                fbxctest: fbxctest,
                fbsimctl: fbsimctl,
                plugins: plugins),
            buildArtifacts: BuildArtifacts(
                appBundle: app,
                runner: runner,
                xcTestBundle: xctestBundle,
                additionalApplicationBundles: additionalApp),
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: simulatorLocalizationSettings,
                watchdogSettings: watchdogSettings),
            testDestinationConfigurations: testDestinations,
            testsToRun: onlyId + onlyTest,
            testDiagnosticOutput: TestDiagnosticOutput(
                iOSVersion: testDestinations[0].testDestination.iOSVersion,
                videoOutputPath: videoPath,
                oslogOutputPath: oslogPath,
                testLogOutputPath: testLogPath))
        try runTests(configuration: configuration, tempFolder: tempFolder)
    }
    
    private func runTests(configuration: LocalTestRunConfiguration, tempFolder: TempFolder) throws {
        log("Configuration: \(configuration)", color: .blue)
        
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>()
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: configuration.auxiliaryPaths.plugins,
            environment: configuration.testExecutionBehavior.environment)
        let schedulerConfiguration = SchedulerConfiguration(
            auxiliaryPaths: configuration.auxiliaryPaths,
            testType: .uiTest,
            buildArtifacts: configuration.buildArtifacts,
            testExecutionBehavior: configuration.testExecutionBehavior,
            simulatorSettings: configuration.simulatorSettings,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration,
            testDiagnosticOutput: configuration.testDiagnosticOutput,
            schedulerDataSource: try LocalRunSchedulerDataSource(
                eventBus: eventBus,
                configuration: configuration,
                runAllTestsIfTestsToRunIsEmpty: true,
                tempFolder: tempFolder),
            onDemandSimulatorPool: onDemandSimulatorPool)
        let scheduler = Scheduler(eventBus: eventBus, configuration: schedulerConfiguration, tempFolder: tempFolder)
        let testingResults = try scheduler.run()
        eventBus.post(event: .tearDown)
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: configuration.reportOutput,
            testDestinationConfigurations: configuration.testDestinationConfigurations)
            .generateOutput()
    }
}
