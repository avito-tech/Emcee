import ArgumentsParser
import Deployer
import DistRun
import Foundation
import Logging
import ModelFactories
import Models
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
        let fileManager = FileManager.default
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        guard let runId = arguments.get(self.runId) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.runId)
        }
        guard let destinationsFile = arguments.get(self.destinations),
            fileManager.fileExists(atPath: destinationsFile) else
        {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.destinations)
        }
        
        let deploymentDestinations: [DeploymentDestination]
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: destinationsFile), options: .mappedIfSafe)
            deploymentDestinations = try decoder.decode([DeploymentDestination].self, from: data)
        } catch {
            throw ArgumentsError.argumentValueCannotBeUsed(KnownStringArguments.destinations, error)
        }
        
        let destinationConfigurations: [DestinationConfiguration]
        if let destinationConfigurationsFile = arguments.get(self.destinationConfigurations) {
            do {
                let data = try Data(
                    contentsOf: URL(fileURLWithPath: destinationConfigurationsFile),
                    options: .mappedIfSafe)
                destinationConfigurations = try decoder.decode([DestinationConfiguration].self, from: data)
            } catch {
                throw ArgumentsError.argumentValueCannotBeUsed(KnownStringArguments.destinationConfigurations, error)
            }
        } else {
            destinationConfigurations = []
        }

        guard let remoteScheduleStrategyRawType = arguments.get(self.remoteScheduleStrategy),
            let remoteScheduleStrategy = ScheduleStrategyType(rawValue: remoteScheduleStrategyRawType) else
        {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.remoteScheduleStrategy)
        }
        
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
        if let simulatorLocalizationSettings = simulatorLocalizationSettings,
            !fileManager.fileExists(atPath: simulatorLocalizationSettings)
        {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.simulatorLocalizationSettings)
        }
        let watchdogSettings = arguments.get(self.watchdogSettings)
        if let watchdogSettings = watchdogSettings, !fileManager.fileExists(atPath: watchdogSettings) {
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
                AdditionalArgumentValidationError.someAdditionalAppBundlesCannotBeFound)
        }
        guard let runner = arguments.get(self.runner), fileManager.fileExists(atPath: runner) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.runner)
        }
        guard let xctestBundle = arguments.get(self.xctestBundle), fileManager.fileExists(atPath: xctestBundle) else {
            throw ArgumentsError.argumentIsMissing(KnownStringArguments.xctestBundle)
        }
        
        guard let singleTestTimeout = arguments.get(self.singleTestTimeout) else {
            throw ArgumentsError.argumentIsMissing(KnownUIntArguments.singleTestTimeout)
        }
        let fbxctestSilenceTimeout = arguments.get(self.fbxctestSilenceTimeout) ?? singleTestTimeout
        let fbxtestFastTimeout = arguments.get(self.fbxtestFastTimeout) ?? singleTestTimeout
        let fbxtestRegularTimeout = arguments.get(self.fbxtestRegularTimeout) ?? singleTestTimeout
        let fbxtestSlowTimeout = arguments.get(self.fbxtestSlowTimeout) ?? singleTestTimeout
        let fbxtestBundleReadyTimeout = arguments.get(self.fbxtestBundleReadyTimeout) ?? singleTestTimeout
        let fbxtestCrashCheckTimeout = arguments.get(self.fbxtestCrashCheckTimeout) ?? singleTestTimeout
        
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
            auxiliaryPaths: try AuxiliaryPathsFactory().createWith(
                fbxctest: ResourceLocation.from(fbxctest),
                fbsimctl: ResourceLocation.from(fbsimctl),
                tempFolder: NSTemporaryDirectory()),
            buildArtifacts: BuildArtifacts(
                appBundle: app,
                runner: runner,
                xcTestBundle: xctestBundle,
                additionalApplicationBundles: additionalApp),
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: simulatorLocalizationSettings,
                watchdogSettings: watchdogSettings),
            testsToRun: testsToRun,
            testDestinationConfigurations: testDestinationConfigurations)
        try run(distRunConfiguration: distRunConfiguration)
    }
    
    func run(distRunConfiguration: DistRunConfiguration) throws {
        log("Using dist run configuration: \(distRunConfiguration)", color: .blue)
        let distRunner = try DistRunner(distRunConfiguration: distRunConfiguration)
        let testingResults = try distRunner.run()
        try ResultingOutputGenerator(
            testingResults: testingResults,
            commonReportOutput: distRunConfiguration.reportOutput,
            testDestinationConfigurations: distRunConfiguration.testDestinationConfigurations)
            .generateOutput()
    }
}
