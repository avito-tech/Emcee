import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import FileSystem
import Foundation
import Logging
import Metrics
import PathLib
import PluginManager
import ProcessController
import QueueModels
import LocalHostDeterminer
import ResourceLocationResolver
import Runner
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import SynchronousWaiter
import TemporaryStuff
import TestArgFile
import UniqueIdentifierGenerator

public final class TestDiscoveryQuerierImpl: TestDiscoveryQuerier {
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let metricRecorder: MetricRecorder
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let pluginEventBusProvider: PluginEventBusProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let version: Version
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        metricRecorder: MetricRecorder,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        version: Version
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.metricRecorder = metricRecorder
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.pluginEventBusProvider = pluginEventBusProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.version = version
    }
    
    public func query(configuration: TestDiscoveryConfiguration) throws -> TestDiscoveryResult {
        let discoveredTests = try obtainDiscoveredTests(configuration: configuration)

        let unavailableTestEntries = requestedTestsNotAvailable(
            configuration: configuration,
            discoveredTests: discoveredTests
        )

        let result = TestDiscoveryResult(
            discoveredTests: discoveredTests,
            unavailableTestsToRun: unavailableTestEntries
        )

        return result
    }

    private func obtainDiscoveredTests(configuration: TestDiscoveryConfiguration) throws -> DiscoveredTests {
        Logger.debug("Trying to fetch cached runtime dump entries for bundle: \(configuration.xcTestBundleLocation)")
        if let cachedRuntimeTests = try? configuration.remoteCache.results(xcTestBundleLocation: configuration.xcTestBundleLocation) {
            Logger.debug("Fetched cached runtime dump entries for test bundle \(configuration.xcTestBundleLocation): \(cachedRuntimeTests)")
            return cachedRuntimeTests
        }

        Logger.debug("No cached runtime dump entries found for bundle: \(configuration.xcTestBundleLocation)")
        let dumpedTests = try discoveredTests(configuration: configuration)

        try? configuration.remoteCache.store(tests: dumpedTests, xcTestBundleLocation: configuration.xcTestBundleLocation)
        return dumpedTests
    }

    
    private func discoveredTests(
        configuration: TestDiscoveryConfiguration
    ) throws -> DiscoveredTests {
        try TimeMeasurerImpl(dateProvider: dateProvider).measure(
            work: {
                let internalTestDiscoverer = createSpecificTestDiscoverer(configuration: configuration)
                
                let foundTestEntries = try internalTestDiscoverer.discoverTestEntries(
                    configuration: configuration
                )
                
                let allTests = foundTestEntries.flatMap { $0.testMethods }
                reportStats(
                    testCaseCount: foundTestEntries.count,
                    testCount: allTests.count,
                    configuration: configuration
                )
                return DiscoveredTests(tests: foundTestEntries)
            },
            result: { error, duration in
                reportDiscoveryDuration(
                    persistentMetricsJobId: configuration.persistentMetricsJobId,
                    duration: duration,
                    isSuccessful: error == nil
                )
            }
        )
    }
    
    private func requestedTestsNotAvailable(
        configuration: TestDiscoveryConfiguration,
        discoveredTests: DiscoveredTests
    ) -> [TestToRun] {
        if configuration.testsToValidate.isEmpty { return [] }
        if discoveredTests.tests.isEmpty { return configuration.testsToValidate }
        
        let availableTestEntries = discoveredTests.tests.flatMap { runtimeDetectedTestEntry -> [TestEntry] in
            runtimeDetectedTestEntry.testMethods.map {
                TestEntry(
                    testName: TestName(
                        className: runtimeDetectedTestEntry.className,
                        methodName: $0
                    ),
                    tags: runtimeDetectedTestEntry.tags,
                    caseId: runtimeDetectedTestEntry.caseId
                )
            }
        }
        let testsToRunMissingInRuntime = configuration.testsToValidate.filter { requestedTestToRun -> Bool in
            switch requestedTestToRun {
            case .testName(let requestedTestName):
                return availableTestEntries.first { $0.testName == requestedTestName } == nil
            case .allDiscoveredTests:
                return false
            }
        }
        return testsToRunMissingInRuntime
    }
    
    private func reportStats(testCaseCount: Int, testCount: Int, configuration: TestDiscoveryConfiguration) {
        let testBundleName = configuration.xcTestBundleLocation.resourceLocation.stringValue.lastPathComponent
        Logger.info("Test discovery in \(configuration.xcTestBundleLocation.resourceLocation): bundle has \(testCaseCount) XCTestCases, \(testCount) tests")
        metricRecorder.capture(
            RuntimeDumpTestCountMetric(
                testBundleName: testBundleName,
                numberOfTests: testCount,
                version: version,
                timestamp: dateProvider.currentDate()
            ),
            RuntimeDumpTestCaseCountMetric(
                testBundleName: testBundleName,
                numberOfTestCases: testCaseCount,
                version: version,
                timestamp: dateProvider.currentDate()
            )
        )
    }
    
    private func reportDiscoveryDuration(persistentMetricsJobId: String, duration: TimeInterval, isSuccessful: Bool) {
        metricRecorder.capture(
            TestDiscoveryDurationMetric(
                host: LocalHostDeterminer.currentHostAddress,
                version: version,
                persistentMetricsJobId: persistentMetricsJobId,
                isSuccessful: isSuccessful,
                duration: duration
            )
        )
    }
    
    private func createSpecificTestDiscoverer(
        configuration: TestDiscoveryConfiguration
    ) -> SpecificTestDiscoverer {
        switch configuration.testDiscoveryMode {
        case .parseFunctionSymbols:
            return ParseFunctionSymbolsTestDiscoverer(
                developerDirLocator: developerDirLocator,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver,
                tempFolder: tempFolder,
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            )
        case .runtimeExecutableLaunch(let appBundleLocation):
            return ExecutableTestDiscoverer(
                appBundleLocation: appBundleLocation,
                developerDirLocator: developerDirLocator,
                resourceLocationResolver: resourceLocationResolver,
                processControllerProvider: processControllerProvider,
                tempFolder: tempFolder,
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            )
        case .runtimeLogicTest(let simulatorControlTool):
            return createRuntimeDumpBasedTestDiscoverer(
                buildArtifacts: .onlyWithXctestBundle(
                    xcTestBundle: XcTestBundle(
                        location: configuration.xcTestBundleLocation,
                        testDiscoveryMode: .runtimeLogicTest
                    )
                ),
                simulatorControlTool: simulatorControlTool,
                testType: .logicTest
            )
        case .runtimeAppTest(let runtimeDumpApplicationTestSupport):
            return createRuntimeDumpBasedTestDiscoverer(
                buildArtifacts: .with(
                    appBundle: runtimeDumpApplicationTestSupport.appBundle,
                    xcTestBundle: XcTestBundle(
                        location: configuration.xcTestBundleLocation,
                        testDiscoveryMode: .runtimeAppTest
                    )
                ),
                simulatorControlTool: runtimeDumpApplicationTestSupport.simulatorControlTool,
                testType: .appTest
            )
        }
    }
    
    private func createRuntimeDumpBasedTestDiscoverer(
        buildArtifacts: BuildArtifacts,
        simulatorControlTool: SimulatorControlTool,
        testType: TestType
    ) -> RuntimeDumpTestDiscoverer {
        RuntimeDumpTestDiscoverer(
            buildArtifacts: buildArtifacts,
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            numberOfAttemptsToPerformRuntimeDump: 3,
            onDemandSimulatorPool: onDemandSimulatorPool,
            pluginEventBusProvider: pluginEventBusProvider,
            resourceLocationResolver: resourceLocationResolver,
            simulatorControlTool: simulatorControlTool,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            testType: testType,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            version: version,
            metricRecorder: metricRecorder
        )
    }
}

private extension BuildArtifacts {
    static func onlyWithXctestBundle(
        xcTestBundle: XcTestBundle
    ) -> BuildArtifacts {
        BuildArtifacts(
            appBundle: nil,
            runner: nil,
            xcTestBundle: xcTestBundle,
            additionalApplicationBundles: []
        )
    }
    
    static func with(
        appBundle: AppBundleLocation,
        xcTestBundle: XcTestBundle
    ) -> BuildArtifacts {
        BuildArtifacts(
            appBundle: appBundle,
            runner: nil,
            xcTestBundle: xcTestBundle,
            additionalApplicationBundles: []
        )
    }
}
