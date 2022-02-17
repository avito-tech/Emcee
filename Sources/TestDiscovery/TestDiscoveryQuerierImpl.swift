import BuildArtifacts
import CommonTestModels
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
    private let globalMetricRecorder: GlobalMetricRecorder
    private let specificMetricRecorderProvider: SpecificMetricRecorderProvider
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let pluginEventBusProvider: PluginEventBusProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let runnerWasteCollectorProvider: RunnerWasteCollectorProvider
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let version: Version
    private let waiter: Waiter
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        globalMetricRecorder: GlobalMetricRecorder,
        specificMetricRecorderProvider: SpecificMetricRecorderProvider,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver,
        runnerWasteCollectorProvider: RunnerWasteCollectorProvider,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        version: Version,
        waiter: Waiter
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.globalMetricRecorder = globalMetricRecorder
        self.specificMetricRecorderProvider = specificMetricRecorderProvider
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.pluginEventBusProvider = pluginEventBusProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.runnerWasteCollectorProvider = runnerWasteCollectorProvider
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
        
        if let cachedRuntimeTests = try? configuration.remoteCache.results(
            xcTestBundleLocation: configuration.testConfiguration.buildArtifacts.xcTestBundle.location
        ) {
            return cachedRuntimeTests
        }

        let dumpedTests = try discoveredTests(configuration: configuration, specificMetricRecorder: specificMetricRecorder)

        try? configuration.remoteCache.store(
            tests: dumpedTests,
            xcTestBundleLocation: configuration.testConfiguration.buildArtifacts.xcTestBundle.location
        )
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
                
                let foundTestEntries = try runRetrying(
                    logger: configuration.logger,
                    xcTestBundleLocation: configuration.testConfiguration.buildArtifacts.xcTestBundle.location,
                    times: configuration.testConfiguration.testExecutionBehavior.numberOfRetries
                ) {
                    try internalTestDiscoverer.discoverTestEntries(
                        configuration: configuration
                    )
                }
                
                let allTests = foundTestEntries.flatMap { $0.testMethods }
                try reportStats(
                    testCaseCount: foundTestEntries.count,
                    testCount: allTests.count,
                    configuration: configuration,
                    specificMetricRecorder: specificMetricRecorder
                )
                return DiscoveredTests(tests: foundTestEntries)
            },
            result: { error, duration in
                reportDiscoveryDuration(
                    persistentMetricsJobId: configuration.analyticsConfiguration.persistentMetricsJobId,
                    duration: duration,
                    isSuccessful: error == nil,
                    specificMetricRecorder: specificMetricRecorder
                )
            }
        )
    }
    
    private func runRetrying<T>(logger: ContextualLogger, xcTestBundleLocation: TestBundleLocation, times: UInt, _ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< times {
            do {
                return try work()
            } catch {
                let pauseDuration = TimeInterval(retryIndex) * 2.0
                logger.error("[\(retryIndex)/\(times)] Failed to get runtime dump for test bundle \(xcTestBundleLocation): \(error)")
                logger.trace("Waiting for \(pauseDuration.loggableInSeconds()) before attempting again")
                waiter.wait(timeout: pauseDuration, description: "Pause between runtime dump retries")
            }
        }
        return try work()
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
    ) throws {
        let lastPathComponent: String
        
        let resourceLocation = configuration.testConfiguration.buildArtifacts.xcTestBundle.location.resourceLocation
        switch resourceLocation {
        case .localFilePath:
            lastPathComponent = try resourceLocation.stringValue().lastPathComponent
        case .remoteUrl(let url, _):
            lastPathComponent = url.lastPathComponent
        }
        let testBundleName = lastPathComponent
        configuration.logger.info("Test discovery in \(resourceLocation): bundle has \(testCaseCount) XCTestCases, \(testCount) tests")
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
        persistentMetricsJobId: String?,
        duration: TimeInterval,
        isSuccessful: Bool,
        specificMetricRecorder: SpecificMetricRecorder
    ) {
        if let persistentMetricsJobId = persistentMetricsJobId {
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
    }
    
    private func createSpecificTestDiscoverer(
        configuration: TestDiscoveryConfiguration,
        specificMetricRecorder: SpecificMetricRecorder
    ) -> SpecificTestDiscoverer {
        switch configuration.testDiscoveryMode {
        case .parseFunctionSymbols:
            return ParseFunctionSymbolsTestDiscoverer(
                developerDirLocator: developerDirLocator,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver
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
        case .runtimeLogicTest:
            return createRuntimeDumpBasedTestDiscoverer(
                buildArtifacts: .iosLogicTests(
                    xcTestBundle: XcTestBundle(
                        location: configuration.testConfiguration.buildArtifacts.xcTestBundle.location,
                        testDiscoveryMode: .runtimeLogicTest
                    )
                ),
                specificMetricRecorder: specificMetricRecorder
            )
        case .runtimeAppTest(let runtimeDumpApplicationTestSupport):
            return createRuntimeDumpBasedTestDiscoverer(
                buildArtifacts: .iosApplicationTests(
                    xcTestBundle: XcTestBundle(
                        location: configuration.testConfiguration.buildArtifacts.xcTestBundle.location,
                        testDiscoveryMode: .runtimeAppTest
                    ),
                    appBundle: runtimeDumpApplicationTestSupport.appBundle
                ),
                specificMetricRecorder: specificMetricRecorder
            )
        }
    }
    
    private func createRuntimeDumpBasedTestDiscoverer(
        buildArtifacts: AppleBuildArtifacts,
        specificMetricRecorder: SpecificMetricRecorder
    ) -> RuntimeDumpTestDiscoverer {
        RuntimeDumpTestDiscoverer(
            buildArtifacts: buildArtifacts,
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            onDemandSimulatorPool: onDemandSimulatorPool,
            pluginEventBusProvider: pluginEventBusProvider,
            resourceLocationResolver: resourceLocationResolver,
            runnerWasteCollectorProvider: runnerWasteCollectorProvider,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            version: version,
            waiter: waiter,
            globalMetricRecorder: globalMetricRecorder,
            specificMetricRecorder: specificMetricRecorder
        )
    }
}
