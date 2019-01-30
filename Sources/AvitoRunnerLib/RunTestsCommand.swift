import ArgumentsParser
import ChromeTracing
import EventBus
import Extensions
import Foundation
import JunitReporting
import Logging
import Models
import PluginManager
import ResourceLocationResolver
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
    private let plugins: OptionArgument<[String]>
    private let runner: OptionArgument<String>
    private let scheduleStrategy: OptionArgument<String>
    private let simulatorLocalizationSettings: OptionArgument<String>
    private let singleTestTimeout: OptionArgument<UInt>
    private let tempFolder: OptionArgument<String>
    private let testArgFile: OptionArgument<String>
    private let testDestinations: OptionArgument<String>
    private let trace: OptionArgument<String>
    private let watchdogSettings: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>
    
    private let resourceLocationResolver = ResourceLocationResolver()
    
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
        plugins = subparser.add(multipleStringArgument: KnownStringArguments.plugin)
        runner = subparser.add(stringArgument: KnownStringArguments.runner)
        scheduleStrategy = subparser.add(stringArgument: KnownStringArguments.scheduleStrategy)
        simulatorLocalizationSettings = subparser.add(stringArgument: KnownStringArguments.simulatorLocalizationSettings)
        singleTestTimeout = subparser.add(intArgument: KnownUIntArguments.singleTestTimeout)
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
        testArgFile = subparser.add(stringArgument: KnownStringArguments.testArgFile)
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        trace = subparser.add(stringArgument: KnownStringArguments.trace)
        watchdogSettings = subparser.add(stringArgument: KnownStringArguments.watchdogSettings)
        xctestBundle = subparser.add(stringArgument: KnownStringArguments.xctestBundle)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let auxiliaryResources = AuxiliaryResources(
            toolResources: ToolResources(
                fbsimctl: FbsimctlLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbsimctl), key: KnownStringArguments.fbsimctl)),
                fbxctest: FbxctestLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.fbxctest), key: KnownStringArguments.fbxctest))
            ),
            plugins: try ArgumentsReader.validateResourceLocations(arguments.get(self.plugins) ?? [], key: KnownStringArguments.plugin).map({ PluginLocation($0) })
        )
        let buildArtifacts = BuildArtifacts(
            appBundle: AppBundleLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.app), key: KnownStringArguments.app)),
            runner: RunnerAppLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.runner), key: KnownStringArguments.runner)),
            xcTestBundle: TestBundleLocation(try ArgumentsReader.validateResourceLocation(arguments.get(self.xctestBundle), key: KnownStringArguments.xctestBundle)),
            additionalApplicationBundles: try ArgumentsReader.validateResourceLocations(arguments.get(self.additionalApp) ?? [], key: KnownStringArguments.additionalApp).map({ AdditionalAppBundleLocation($0) })
        )
        let reportOutput = ReportOutput(
            junit: try ArgumentsReader.validateNotNil(arguments.get(self.junit), key: KnownStringArguments.junit),
            tracingReport: try ArgumentsReader.validateNotNil(arguments.get(self.trace), key: KnownStringArguments.trace)
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
        let testRunExecutionBehavior = TestRunExecutionBehavior(
            numberOfRetries: try ArgumentsReader.validateNotNil(arguments.get(self.numberOfRetries), key: KnownUIntArguments.numberOfRetries),
            numberOfSimulators: try ArgumentsReader.validateNotNil(arguments.get(self.numberOfSimulators), key: KnownUIntArguments.numberOfSimulators),
            environment: try ArgumentsReader.environment(arguments.get(self.environment), key: KnownStringArguments.environment),
            scheduleStrategy: try ArgumentsReader.scheduleStrategy(arguments.get(self.scheduleStrategy), key: KnownStringArguments.scheduleStrategy)
        )
        let eventBus = try EventBusFactory.createEventBusWithAttachedPluginManager(
            pluginLocations: auxiliaryResources.plugins,
            resourceLocationResolver: resourceLocationResolver
        )
        defer { eventBus.tearDown() }
        
        let onlyId: [TestToRun] = (arguments.get(self.onlyId) ?? []).map { TestToRun.caseId($0) }
        let onlyTest: [TestToRun] = (arguments.get(self.onlyTest) ?? []).map { TestToRun.testName($0) }
        let tempFolder = try TempFolder.with(stringPath: try ArgumentsReader.validateNotNil(arguments.get(self.tempFolder), key: KnownStringArguments.tempFolder))
        let testArgFile = try ArgumentsReader.testArgFile(arguments.get(self.testArgFile), key: KnownStringArguments.testArgFile)
        let testDestinationConfigurations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        
        let testEntriesValidator = TestEntriesValidator(
            eventBus: eventBus,
            runtimeDumpConfiguration: RuntimeDumpConfiguration(
                fbxctest: auxiliaryResources.toolResources.fbxctest,
                xcTestBundle: buildArtifacts.xcTestBundle,
                testDestination: testDestinationConfigurations.elementAtIndex(0, "First test destination").testDestination,
                testsToRun: onlyId + onlyTest + testArgFile.entries.map { $0.testToRun }
            ),
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        let validatedTestEntries = try testEntriesValidator.validatedTestEntries()
        
        let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
            validatedEnteries: validatedTestEntries,
            explicitTestsToRun: determineTestsToRun(
                onlyTests: onlyId + onlyTest,
                testArgFile: testArgFile,
                validatedTestEntries: validatedTestEntries
            ),
            testArgEntries: testArgFile.entries,
            commonTestExecutionBehavior: TestExecutionBehavior(
                environment: testRunExecutionBehavior.environment,
                numberOfRetries: testRunExecutionBehavior.numberOfRetries
            ),
            commonTestDestinations: testDestinationConfigurations.map { $0.testDestination },
            commonBuildArtifacts: buildArtifacts
        )

        let configuration = try LocalTestRunConfiguration(
            reportOutput: reportOutput,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testRunExecutionBehavior: testRunExecutionBehavior,
            auxiliaryResources: auxiliaryResources,
            simulatorSettings: simulatorSettings,
            testEntryConfigurations: testEntryConfigurationGenerator.createTestEntryConfigurations(),
            testDestinationConfigurations: testDestinationConfigurations
        )
        try runTests(configuration: configuration, eventBus: eventBus, tempFolder: tempFolder)
    }
    
    private func determineTestsToRun(
        onlyTests: [TestToRun],
        testArgFile: TestArgFile,
        validatedTestEntries: [TestToRun : [TestEntry]]
        ) -> [TestToRun]
    {
        if onlyTests.isEmpty && testArgFile.entries.isEmpty {
            // If we do not pass any tests to run explicitly either by --only-* flag or via --test-arg-file,
            // we use runtime dump information to form array of tests to run
            return Array(validatedTestEntries.keys)
        } else {
            return onlyTests
        }
    }
    
    private func runTests(configuration: LocalTestRunConfiguration, eventBus: EventBus, tempFolder: TempFolder) throws {
        Logger.verboseDebug("Configuration: \(configuration)")
        
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let schedulerConfiguration = SchedulerConfiguration(
            testType: .uiTest,
            testRunExecutionBehavior: configuration.testRunExecutionBehavior,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration,
            schedulerDataSource: LocalRunSchedulerDataSource(configuration: configuration),
            onDemandSimulatorPool: onDemandSimulatorPool)
        let scheduler = Scheduler(
            eventBus: eventBus,
            configuration: schedulerConfiguration,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver)
        let testingResults = try scheduler.run()
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: configuration.reportOutput,
            testDestinationConfigurations: configuration.testDestinationConfigurations)
            .generateOutput()
    }
}
