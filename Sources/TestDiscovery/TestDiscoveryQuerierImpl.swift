import BuildArtifacts
import DeveloperDirLocator
import Extensions
import Foundation
import Logging
import Metrics
import Models
import PathLib
import PluginManager
import ResourceLocationResolver
import Runner
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator

public final class TestDiscoveryQuerierImpl: TestDiscoveryQuerier {
    private let developerDirLocator: DeveloperDirLocator
    private let numberOfAttemptsToPerformRuntimeDump: UInt
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let pluginEventBusProvider: PluginEventBusProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TemporaryFolder
    private let testEntryToQueryRuntimeDump: TestEntry
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let remoteCache: RuntimeDumpRemoteCache
    
    public init(
        developerDirLocator: DeveloperDirLocator,
        numberOfAttemptsToPerformRuntimeDump: UInt,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        pluginEventBusProvider: PluginEventBusProvider,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder,
        testEntryToQueryRuntimeDump: TestEntry = TestEntry(testName: TestName(className: "NonExistingTest", methodName: "fakeTest"), tags: [], caseId: nil),
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        remoteCache: RuntimeDumpRemoteCache
    ) {
        self.developerDirLocator = developerDirLocator
        self.numberOfAttemptsToPerformRuntimeDump = max(numberOfAttemptsToPerformRuntimeDump, 1)
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.pluginEventBusProvider = pluginEventBusProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
        self.testEntryToQueryRuntimeDump = testEntryToQueryRuntimeDump
        self.testRunnerProvider = testRunnerProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.remoteCache = remoteCache
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
        if let cachedRuntimeTests = try? remoteCache.results(xcTestBundleLocation: configuration.xcTestBundleLocation) {
            Logger.debug("Fetched cached runtime dump entries for test bundle \(configuration.xcTestBundleLocation): \(cachedRuntimeTests)")
            return cachedRuntimeTests
        }

        Logger.debug("No cached runtime dump entries found for bundle: \(configuration.xcTestBundleLocation)")
        let dumpedTests =  try runRetrying(times: numberOfAttemptsToPerformRuntimeDump) {
            try discoveredTests(configuration: configuration)
        }

        try? remoteCache.store(tests: dumpedTests, xcTestBundleLocation: configuration.xcTestBundleLocation)
        return dumpedTests
    }

    private func runRetrying<T>(times: UInt, _ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< times {
            do {
                return try work()
            } catch {
                Logger.error("Failed to get runtime dump, error: \(error)")
                SynchronousWaiter().wait(timeout: TimeInterval(retryIndex) * 2.0, description: "Pause between runtime dump retries")
            }
        }
        return try work()
    }
    
    private func discoveredTests(configuration: TestDiscoveryConfiguration) throws -> DiscoveredTests {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [uniqueIdentifierGenerator.generate()])
        Logger.debug("Will dump runtime tests into file: \(runtimeEntriesJSONPath)")

        let allocatedSimulator = try simulatorForTestDiscovery(configuration: configuration)
        defer { allocatedSimulator.releaseSimulator() }

        let runnerConfiguration = buildRunnerConfiguration(
            configuration: configuration,
            runtimeEntriesJSONPath: runtimeEntriesJSONPath
        )
        let runner = Runner(
            configuration: runnerConfiguration,
            developerDirLocator: developerDirLocator,
            pluginEventBusProvider: pluginEventBusProvider,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider
        )
        let runnerRunResult = try runner.runOnce(
            entriesToRun: [testEntryToQueryRuntimeDump],
            developerDir: configuration.developerDir,
            simulator: allocatedSimulator.simulator
        )
        
        guard let data = try? Data(contentsOf: runtimeEntriesJSONPath.fileUrl),
            let foundTestEntries = try? JSONDecoder().decode([DiscoveredTestEntry].self, from: data)
            else {
                runnerRunResult.dumpStandardStreams()
                throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath)
        }
        
        let allTests = foundTestEntries.flatMap { $0.testMethods }
        reportStats(
            testCaseCount: foundTestEntries.count,
            testCount: allTests.count,
            configuration: configuration
        )
        
        return DiscoveredTests(tests: foundTestEntries)
    }

    private func buildRunnerConfiguration(
        configuration: TestDiscoveryConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> RunnerConfiguration {
        let environment = self.environment(configuration: configuration, runtimeEntriesJSONPath: runtimeEntriesJSONPath)

        switch configuration.testDiscoveryMode {
        case .runtimeLogicTest:
            return RunnerConfiguration(
                buildArtifacts: BuildArtifacts.onlyWithXctestBundle(
                    xcTestBundle: XcTestBundle(
                        location: configuration.xcTestBundleLocation,
                        testDiscoveryMode: .runtimeLogicTest
                    )
                ),
                environment: environment,
                pluginLocations: configuration.pluginLocations,
                simulatorSettings: configuration.simulatorSettings,
                testRunnerTool: configuration.testRunnerTool,
                testTimeoutConfiguration: configuration.testTimeoutConfiguration,
                testType: .logicTest
            )
        case .runtimeAppTest(let runtimeDumpApplicationTestSupport):
            return RunnerConfiguration(
                buildArtifacts: BuildArtifacts(
                    appBundle: runtimeDumpApplicationTestSupport.appBundle,
                    runner: nil,
                    xcTestBundle: XcTestBundle(
                        location: configuration.xcTestBundleLocation,
                        testDiscoveryMode: .runtimeAppTest
                    ),
                    additionalApplicationBundles: []
                ),
                environment: environment,
                pluginLocations: configuration.pluginLocations,
                simulatorSettings: configuration.simulatorSettings,
                testRunnerTool: configuration.testRunnerTool,
                testTimeoutConfiguration: configuration.testTimeoutConfiguration,
                testType: .appTest
            )
        }
    }

    private func simulatorForTestDiscovery(
        configuration: TestDiscoveryConfiguration
    ) throws -> AllocatedSimulator {
        let simulatorControlTool: SimulatorControlTool
        
        switch configuration.testDiscoveryMode {
        case .runtimeLogicTest(let tool):
            simulatorControlTool = tool
        case .runtimeAppTest(let runtimeDumpApplicationTestSupport):
            simulatorControlTool = runtimeDumpApplicationTestSupport.simulatorControlTool
        }
        
        let simulatorPool = try onDemandSimulatorPool.pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: configuration.developerDir,
                testDestination: configuration.testDestination,
                simulatorControlTool: simulatorControlTool
            )
        )
        return try simulatorPool.allocateSimulator(simulatorOperationTimeouts: configuration.simulatorOperationTimeouts)
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
        Logger.info("Runtime dump of \(configuration.xcTestBundleLocation.resourceLocation): bundle has \(testCaseCount) XCTestCases, \(testCount) tests")
        MetricRecorder.capture(
            RuntimeDumpTestCountMetric(testBundleName: testBundleName, numberOfTests: testCount),
            RuntimeDumpTestCaseCountMetric(testBundleName: testBundleName, numberOfTestCases: testCaseCount)
        )
    }
    
    private func environment(
        configuration: TestDiscoveryConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> [String: String] {
        var environment = configuration.testExecutionBehavior.environment
        environment["EMCEE_RUNTIME_TESTS_EXPORT_PATH"] = runtimeEntriesJSONPath.pathString
        return environment
    }
}
