import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import FileSystem
import Foundation
import EmceeLogging
import Metrics
import MetricsExtensions
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
import TestArgFile
import Tmp
import UniqueIdentifierGenerator

public final class TestDiscoveryQuerierImpl: TestDiscoveryQuerier {
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let globalMetricRecorder: GlobalMetricRecorder
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let pluginEventBusProvider: PluginEventBusProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let version: Version
    private let waiter: Waiter
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        globalMetricRecorder: GlobalMetricRecorder,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        version: Version,
        waiter: Waiter
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.logger = logger.forType(Self.self)
        self.globalMetricRecorder = globalMetricRecorder
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.pluginEventBusProvider = pluginEventBusProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.version = version
        self.waiter = waiter
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
        let specificMetricRecorder = try specificMetricRecorderProvider.specificMetricRecorder(
            analyticsConfiguration: configuration.analyticsConfiguration
        )
        
        logger.debug("Trying to fetch cached runtime dump entries for bundle: \(configuration.xcTestBundleLocation)")
        if let cachedRuntimeTests = try? configuration.remoteCache.results(xcTestBundleLocation: configuration.xcTestBundleLocation) {
            logger.debug("Fetched cached runtime dump entries for test bundle \(configuration.xcTestBundleLocation): \(cachedRuntimeTests)")
            return cachedRuntimeTests
        }

        logger.debug("No cached runtime dump entries found for bundle: \(configuration.xcTestBundleLocation)")
        let dumpedTests = try discoveredTests(configuration: configuration, specificMetricRecorder: specificMetricRecorder)

        try? configuration.remoteCache.store(tests: dumpedTests, xcTestBundleLocation: configuration.xcTestBundleLocation)
        return dumpedTests
    }

    
    private func discoveredTests(
        configuration: TestDiscoveryConfiguration,
        specificMetricRecorder: SpecificMetricRecorder
    ) throws -> DiscoveredTests {
        try TimeMeasurerImpl(dateProvider: dateProvider).measure(
            work: {
                let internalTestDiscoverer = createSpecificTestDiscoverer(
                    configuration: configuration,
                    specificMetricRecorder: specificMetricRecorder
                )
                
                let foundTestEntries = try internalTestDiscoverer.discoverTestEntries(
                    configuration: configuration
                )
                
                let allTests = foundTestEntries.flatMap { $0.testMethods }
                reportStats(
                    testCaseCount: foundTestEntries.count,
                    testCount: allTests.count,
                    configuration: configuration,
                    specificMetricRecorder: specificMetricRecorder
                )
                return DiscoveredTests(tests: foundTestEntries)
            },
            result: { error, duration in
                reportDiscoveryDuration(
                    persistentMetricsJobId: configuration.persistentMetricsJobId,
                    duration: duration,
                    isSuccessful: error == nil,
                    specificMetricRecorder: specificMetricRecorder
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
    
    private func reportStats(
        testCaseCount: Int,
        testCount: Int,
        configuration: TestDiscoveryConfiguration,
        specificMetricRecorder: SpecificMetricRecorder
    ) {
        let testBundleName = configuration.xcTestBundleLocation.resourceLocation.stringValue.lastPathComponent
        logger.info("Test discovery in \(configuration.xcTestBundleLocation.resourceLocation): bundle has \(testCaseCount) XCTestCases, \(testCount) tests")
        specificMetricRecorder.capture(
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
    
    private func reportDiscoveryDuration(
        persistentMetricsJobId: String,
        duration: TimeInterval,
        isSuccessful: Bool,
        specificMetricRecorder: SpecificMetricRecorder
    ) {
        specificMetricRecorder.capture(
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
        configuration: TestDiscoveryConfiguration,
        specificMetricRecorder: SpecificMetricRecorder
    ) -> SpecificTestDiscoverer {
        switch configuration.testDiscoveryMode {
        case .parseFunctionSymbols:
            return ParseFunctionSymbolsTestDiscoverer(
                developerDirLocator: developerDirLocator,
                logger: logger,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver,
                tempFolder: tempFolder,
                uniqueIdentifierGenerator: uniqueIdentifierGenerator
            )
        case .runtimeExecutableLaunch(let appBundleLocation):
            return ExecutableTestDiscoverer(
                appBundleLocation: appBundleLocation,
                developerDirLocator: developerDirLocator,
                logger: logger,
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
                testType: .logicTest,
                specificMetricRecorder: specificMetricRecorder
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
                testType: .appTest,
                specificMetricRecorder: specificMetricRecorder
            )
        }
    }
    
    private func createRuntimeDumpBasedTestDiscoverer(
        buildArtifacts: BuildArtifacts,
        simulatorControlTool: SimulatorControlTool,
        testType: TestType,
        specificMetricRecorder: SpecificMetricRecorder
    ) -> RuntimeDumpTestDiscoverer {
        RuntimeDumpTestDiscoverer(
            buildArtifacts: buildArtifacts,
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            logger: logger,
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
            waiter: waiter,
            globalMetricRecorder: globalMetricRecorder,
            specificMetricRecorder: specificMetricRecorder
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
