import ArgumentsParser
import ChromeTracing
import Extensions
import Foundation
import JunitReporting
import Logging
import ModelFactories
import Models
import Runner
import RuntimeDump
import ScheduleStrategy
import Scheduler
import SimulatorPool
import Utility

final class RunTestsCommand: Command {
    let command = "runTests"
    let overview = "Runs UI tests and writes report"
    
    private let testDestinations: OptionArgument<String>
    private let onlyId: OptionArgument<[UInt]>
    private let onlyTest: OptionArgument<[String]>
    
    private let junit: OptionArgument<String>
    private let trace: OptionArgument<String>
    
    private let numberOfSimulators: OptionArgument<UInt>
    private let numberOfRetries: OptionArgument<UInt>
    private let scheduleStrategy: OptionArgument<String>
    private let environment: OptionArgument<String>
    
    private let simulatorLocalizationSettings: OptionArgument<String>
    private let watchdogSettings: OptionArgument<String>
    
    private let fbxctest: OptionArgument<String>
    private let fbsimctl: OptionArgument<String>
    
    private let app: OptionArgument<String>
    private let additionalApp: OptionArgument<[String]>
    private let runner: OptionArgument<String>
    private let xctestBundle: OptionArgument<String>

    private let tempFolder: OptionArgument<String>
    private let videoPath: OptionArgument<String>
    private let oslogPath: OptionArgument<String>
    private let testLogPath: OptionArgument<String>
    
    private let singleTestTimeout: OptionArgument<UInt>
    private let fbxctestSilenceTimeout: OptionArgument<UInt>
    private let fbxtestFastTimeout: OptionArgument<UInt>
    private let fbxtestRegularTimeout: OptionArgument<UInt>
    private let fbxtestSlowTimeout: OptionArgument<UInt>
    private let fbxtestBundleReadyTimeout: OptionArgument<UInt>
    private let fbxtestCrashCheckTimeout: OptionArgument<UInt>
    
    required init(parser: ArgumentParser) {
        let subparser = parser.add(subparser: command, overview: overview)
        
        testDestinations = subparser.add(stringArgument: KnownStringArguments.testDestinations)
        onlyId = subparser.add(multipleIntArgument: KnownUIntArguments.onlyId)
        onlyTest = subparser.add(multipleStringArgument: KnownStringArguments.onlyTest)
        
        junit = subparser.add(stringArgument: KnownStringArguments.junit)
        trace = subparser.add(stringArgument: KnownStringArguments.trace)
        
        numberOfSimulators = subparser.add(intArgument: KnownUIntArguments.numberOfSimulators)
        numberOfRetries = subparser.add(intArgument: KnownUIntArguments.numberOfRetries)
        scheduleStrategy = subparser.add(stringArgument: KnownStringArguments.scheduleStrategy)
        environment = subparser.add(stringArgument: KnownStringArguments.environment)
        
        simulatorLocalizationSettings = subparser.add(stringArgument: KnownStringArguments.simulatorLocalizationSettings)
        watchdogSettings = subparser.add(stringArgument: KnownStringArguments.watchdogSettings)
        
        fbxctest = subparser.add(stringArgument: KnownStringArguments.fbxctest)
        fbsimctl = subparser.add(stringArgument: KnownStringArguments.fbsimctl)
        
        app = subparser.add(stringArgument: KnownStringArguments.app)
        additionalApp = subparser.add(multipleStringArgument: KnownStringArguments.additionalApp)
        runner = subparser.add(stringArgument: KnownStringArguments.runner)
        xctestBundle = subparser.add(stringArgument: KnownStringArguments.xctestBundle)
        
        tempFolder = subparser.add(stringArgument: KnownStringArguments.tempFolder)
        videoPath = subparser.add(stringArgument: KnownStringArguments.videoPath)
        oslogPath = subparser.add(stringArgument: KnownStringArguments.oslogPath)
        testLogPath = subparser.add(stringArgument: KnownStringArguments.testLogPath)

        singleTestTimeout = subparser.add(intArgument: KnownUIntArguments.singleTestTimeout)
        fbxctestSilenceTimeout = subparser.add(intArgument: KnownUIntArguments.fbxctestSilenceTimeout)
        fbxtestFastTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestFastTimeout)
        fbxtestRegularTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestRegularTimeout)
        fbxtestSlowTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestSlowTimeout)
        fbxtestBundleReadyTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestBundleReadyTimeout)
        fbxtestCrashCheckTimeout = subparser.add(intArgument: KnownUIntArguments.fbxtestCrashCheckTimeout)
    }
    
    func run(with arguments: ArgumentParser.Result) throws {
        let fileManager = FileManager.default
        let decoder = JSONDecoder()
        
        guard let testDestinationFile = arguments.get(self.testDestinations) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.testDestinations)
        }
        let testDestinationConfigurations: [TestDestinationConfiguration]
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: testDestinationFile))
            testDestinationConfigurations = try decoder.decode([TestDestinationConfiguration].self, from: data)
        } catch {
            throw ArgumentsError.argumentValueCannotBeUsed(KnownStringArguments.testDestinations, error)
        }
        
        
        let onlyId: [TestToRun] = (arguments.get(self.onlyId) ?? []).map { TestToRun.caseId($0) }
        let onlyTest: [TestToRun] = (arguments.get(self.onlyTest) ?? []).map { TestToRun.testName($0) }
        let testsToRun: [TestToRun] = [onlyId, onlyTest].flatMap { $0 }
        
        guard let junit = arguments.get(self.junit) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.junit)
        }
        guard let trace = arguments.get(self.trace) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.trace)
        }
        
        guard let numberOfSimulators = arguments.get(self.numberOfSimulators) else {
            throw ArgumentsError.argumentIsMissing(KnownUIntArguments.numberOfSimulators)
        }
        guard let numberOfRetries = arguments.get(self.numberOfRetries) else {
            throw ArgumentsError.argumentIsMissing(KnownUIntArguments.numberOfRetries)
        }
        guard let strategyRawType = arguments.get(self.scheduleStrategy),
            let scheduleStrategy = ScheduleStrategyType(rawValue: strategyRawType) else
        {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.scheduleStrategy)
        }
        
        let environmentValues: [String: String]
        if let environmentFile = arguments.get(self.environment), fileManager.fileExists(atPath: environmentFile) {
            do {
                let environmentData = try Data(contentsOf: URL(fileURLWithPath: environmentFile))
                environmentValues = try JSONDecoder().decode([String: String].self, from: environmentData)
            } catch let error {
                log("Unable to read or decode environments file", color: .red)
                throw ArgumentsError.argumentValueCannotBeUsed(KnownStringArguments.environment, error)
            }
        } else {
            environmentValues = [:]
        }

        let simulatorLocalizationSettings = arguments.get(self.simulatorLocalizationSettings)
        if let simulatorLocalizationSettings = simulatorLocalizationSettings, !fileManager.fileExists(atPath: simulatorLocalizationSettings) {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.simulatorLocalizationSettings)
        }

        let watchdogSettings = arguments.get(self.watchdogSettings)
        if let watchdogSettings = watchdogSettings, fileManager.fileExists(atPath: watchdogSettings) {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.watchdogSettings)
        }
        
        guard let fbxctest = arguments.get(self.fbxctest) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.fbxctest)
        }
        guard let fbsimctl = arguments.get(self.fbsimctl) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.fbsimctl)
        }
        
        guard let app = arguments.get(self.app), fileManager.fileExists(atPath: app) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.app)
        }
        let additionalApp = arguments.get(self.additionalApp) ?? []
        if !fileManager.filesExist(additionalApp) {
            throw ArgumentsError.argumentValueCannotBeUsed(
                KnownStringArguments.additionalApp,
                AdditionalAppValidationError.someAdditionalAppBundlesCannotBeFound)
        }
        guard let runner = arguments.get(self.runner), fileManager.fileExists(atPath: runner) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.runner)
        }
        guard let xctestBundle = arguments.get(self.xctestBundle), fileManager.fileExists(atPath: xctestBundle) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.xctestBundle)
        }
        
        guard let tempFolder = arguments.get(self.tempFolder) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.tempFolder)
        }
        
        let videoPath = arguments.get(self.videoPath)
        let oslogPath = arguments.get(self.oslogPath)
        let testLogPath = arguments.get(self.testLogPath)
        
        guard let singleTestTimeout = arguments.get(self.singleTestTimeout) else {
            throw ArgumentsError.argumentIsMissing(KnownUIntArguments.singleTestTimeout)
        }
        let fbxctestSilenceTimeout = arguments.get(self.fbxctestSilenceTimeout) ?? singleTestTimeout
        let fbxtestFastTimeout = arguments.get(self.fbxtestFastTimeout) ?? singleTestTimeout
        let fbxtestRegularTimeout = arguments.get(self.fbxtestRegularTimeout) ?? singleTestTimeout
        let fbxtestSlowTimeout = arguments.get(self.fbxtestSlowTimeout) ?? singleTestTimeout
        let fbxtestBundleReadyTimeout = arguments.get(self.fbxtestBundleReadyTimeout) ?? singleTestTimeout
        let fbxtestCrashCheckTimeout = arguments.get(self.fbxtestCrashCheckTimeout) ?? singleTestTimeout
        
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
            auxiliaryPaths: AuxiliaryPathsFactory().createWith(
                fbxctest: ResourceLocation.from(fbxctest),
                fbsimctl: ResourceLocation.from(fbsimctl),
                tempFolder: tempFolder),
            buildArtifacts: BuildArtifacts(
                appBundle: app,
                runner: runner,
                xcTestBundle: xctestBundle,
                additionalApplicationBundles: additionalApp),
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: simulatorLocalizationSettings,
                watchdogSettings: watchdogSettings),
            testDestinationConfigurations: testDestinationConfigurations,
            testsToRun: testsToRun,
            testDiagnosticOutput: TestDiagnosticOutput(
                iOSVersion: testDestinationConfigurations[0].testDestination.iOSVersion,
                videoOutputPath: videoPath,
                oslogOutputPath: oslogPath,
                testLogOutputPath: testLogPath))
        try runTests(configuration: configuration)
    }
    
    private func runTests(configuration: LocalTestRunConfiguration) throws {
        log("Configuration: \(configuration)", color: .blue)
        
        let onDemandSimulatorPool = OnDemandSimulatorPool<DefaultSimulatorController>()
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        let schedulerConfiguration = SchedulerConfiguration(
            auxiliaryPaths: configuration.auxiliaryPaths,
            testType: .uiTest,
            buildArtifacts: configuration.buildArtifacts,
            testExecutionBehavior: configuration.testExecutionBehavior,
            simulatorSettings: configuration.simulatorSettings,
            testTimeoutConfiguration: configuration.testTimeoutConfiguration,
            testDiagnosticOutput: configuration.testDiagnosticOutput,
            schedulerDataSource: try LocalRunSchedulerDataSource(
                configuration: configuration,
                runAllTestsIfTestsToRunIsEmpty: true),
            onDemandSimulatorPool: onDemandSimulatorPool)
        let scheduler = Scheduler(configuration: schedulerConfiguration)
        let testingResults = try scheduler.run()
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: configuration.reportOutput,
            testDestinationConfigurations: configuration.testDestinationConfigurations)
            .generateOutput()
    }
}
