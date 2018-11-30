import ArgumentsParser
import Deployer
import DistRun
import EventBus
import Foundation
import Logging
import Models
import PluginManager
import ResourceLocationResolver
import ScheduleStrategy
import TempFolder
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
        let simulatorSettings = SimulatorSettings(
            simulatorLocalizationSettings: try ArgumentsReader.validateNilOrFileExists(arguments.get(self.simulatorLocalizationSettings), key: KnownStringArguments.simulatorLocalizationSettings),
            watchdogSettings: try ArgumentsReader.validateNilOrFileExists(arguments.get(self.watchdogSettings), key: KnownStringArguments.watchdogSettings)
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
            resourceLocationResolver: resourceLocationResolver,
            environment: testRunExecutionBehavior.environment
        )
        defer { eventBus.tearDown() }

        let deploymentDestinations = try ArgumentsReader.deploymentDestinations(arguments.get(self.destinations), key: KnownStringArguments.destinations)
        let destinationConfigurations = try ArgumentsReader.destinationConfigurations(arguments.get(self.destinationConfigurations), key: KnownStringArguments.destinationConfigurations)
        let onlyId: [TestToRun] = (arguments.get(self.onlyId) ?? []).map { TestToRun.caseId($0) }
        let onlyTest: [TestToRun] = (arguments.get(self.onlyTest) ?? []).map { TestToRun.testName($0) }
        let remoteScheduleStrategy = try ArgumentsReader.scheduleStrategy(arguments.get(self.remoteScheduleStrategy), key: KnownStringArguments.remoteScheduleStrategy)
        let runId = try ArgumentsReader.validateNotNil(arguments.get(self.runId), key: KnownStringArguments.runId)
        let tempFolder = try TempFolder()
        let testArgFile = try ArgumentsReader.testArgFile(arguments.get(self.testArgFile), key: KnownStringArguments.testArgFile)
        let testDestinationConfigurations = try ArgumentsReader.testDestinations(arguments.get(self.testDestinations), key: KnownStringArguments.testDestinations)
        
        let testEntriesValidator = TestEntriesValidator(
            eventBus: eventBus,
            runtimeDumpConfiguration: RuntimeDumpConfiguration(
                fbxctest: auxiliaryResources.toolResources.fbxctest,
                xcTestBundle: buildArtifacts.xcTestBundle,
                simulatorSettings: simulatorSettings,
                testDestination: testDestinationConfigurations.elementAtIndex(0, "First test destination").testDestination,
                testsToRun: onlyId + onlyTest + testArgFile.entries.map { $0.testToRun }
            ),
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder
        )
        let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
            validatedEnteries: try testEntriesValidator.validatedTestEntries(),
            explicitTestsToRun: onlyId + onlyTest,
            testArgEntries: testArgFile.entries,
            commonTestExecutionBehavior: TestExecutionBehavior(numberOfRetries: testRunExecutionBehavior.numberOfRetries),
            commonTestDestinations: testDestinationConfigurations.map { $0.testDestination },
            commonBuildArtifacts: buildArtifacts
        )
        
        let distRunConfiguration = DistRunConfiguration(
            runId: runId,
            reportOutput: reportOutput,
            destinations: deploymentDestinations,
            destinationConfigurations: destinationConfigurations,
            remoteScheduleStrategyType: remoteScheduleStrategy,
            testTimeoutConfiguration: testTimeoutConfiguration,
            testRunExecutionBehavior: testRunExecutionBehavior,
            auxiliaryResources: auxiliaryResources,
            simulatorSettings: simulatorSettings,
            testEntryConfigurations: testEntryConfigurationGenerator.createTestEntryConfigurations(),
            testDestinationConfigurations: testDestinationConfigurations
        )
        try run(distRunConfiguration: distRunConfiguration, eventBus: eventBus, tempFolder: tempFolder)
    }
    
    func run(distRunConfiguration: DistRunConfiguration, eventBus: EventBus, tempFolder: TempFolder) throws {
        log("Using dist run configuration: \(distRunConfiguration)", color: .blue)
        
        let distRunner = DistRunner(
            eventBus: eventBus,
            distRunConfiguration: distRunConfiguration,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder)
        let testingResults = try distRunner.run()
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: distRunConfiguration.reportOutput,
            testDestinationConfigurations: distRunConfiguration.testDestinationConfigurations)
            .generateOutput()
    }
}
