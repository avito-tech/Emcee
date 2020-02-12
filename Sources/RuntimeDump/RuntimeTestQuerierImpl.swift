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
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator

public final class RuntimeTestQuerierImpl: RuntimeTestQuerier {
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
    
    public func queryRuntime(configuration: RuntimeDumpConfiguration) throws -> RuntimeQueryResult {
        let testsInRuntimeDump = try obtainAvailableRuntimeTests(configuration: configuration)

        let unavailableTestEntries = requestedTestsNotAvailableInRuntime(
            testsInRuntimeDump: testsInRuntimeDump,
            configuration: configuration
        )

        let result = RuntimeQueryResult(
            unavailableTestsToRun: unavailableTestEntries,
            testsInRuntimeDump: testsInRuntimeDump
        )

        return result
    }

    private func obtainAvailableRuntimeTests(configuration: RuntimeDumpConfiguration) throws -> TestsInRuntimeDump {
        Logger.debug("Trying to fetch cached runtime dump entries for bundle: \(configuration.xcTestBundleLocation)")
        if let cachedRuntimeTests = try? remoteCache.results(xcTestBundleLocation: configuration.xcTestBundleLocation) {
            Logger.debug("Fetched cached runtime dump entries for test bundle \(configuration.xcTestBundleLocation): \(cachedRuntimeTests)")
            return cachedRuntimeTests
        }

        Logger.debug("No cached runtime dump entries found for bundle: \(configuration.xcTestBundleLocation)")
        let dumpedTests =  try runRetrying(times: numberOfAttemptsToPerformRuntimeDump) {
            try availableTestsInRuntime(configuration: configuration)
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
    
    private func availableTestsInRuntime(configuration: RuntimeDumpConfiguration) throws -> TestsInRuntimeDump {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [uniqueIdentifierGenerator.generate()])
        Logger.debug("Will dump runtime tests into file: \(runtimeEntriesJSONPath)")

        let allocatedSimulator = try simulatorForRuntimeDump(configuration: configuration)
        defer { allocatedSimulator.releaseSimulator() }

        let runnerConfiguration = buildRunnerConfiguration(
            dumpConfiguration: configuration,
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
            let foundTestEntries = try? JSONDecoder().decode([RuntimeTestEntry].self, from: data)
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
        
        return TestsInRuntimeDump(tests: foundTestEntries)
    }

    private func buildRunnerConfiguration(
        dumpConfiguration: RuntimeDumpConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> RunnerConfiguration {
        let environment = self.environment(configuration: dumpConfiguration, runtimeEntriesJSONPath: runtimeEntriesJSONPath)

        switch dumpConfiguration.runtimeDumpMode {
        case .logicTest:
            return RunnerConfiguration(
                buildArtifacts: BuildArtifacts.onlyWithXctestBundle(
                    xcTestBundle: XcTestBundle(
                        location: dumpConfiguration.xcTestBundleLocation,
                        runtimeDumpKind: .logicTest
                    )
                ),
                environment: environment,
                pluginLocations: dumpConfiguration.pluginLocations,
                simulatorSettings: dumpConfiguration.simulatorSettings,
                testRunnerTool: dumpConfiguration.testRunnerTool,
                testTimeoutConfiguration: dumpConfiguration.testTimeoutConfiguration,
                testType: .logicTest
            )
        case .appTest(let runtimeDumpApplicationTestSupport):
            return RunnerConfiguration(
                buildArtifacts: BuildArtifacts(
                    appBundle: runtimeDumpApplicationTestSupport.appBundle,
                    runner: nil,
                    xcTestBundle: XcTestBundle(
                        location: dumpConfiguration.xcTestBundleLocation,
                        runtimeDumpKind: .appTest
                    ),
                    additionalApplicationBundles: []
                ),
                environment: environment,
                pluginLocations: dumpConfiguration.pluginLocations,
                simulatorSettings: dumpConfiguration.simulatorSettings,
                testRunnerTool: dumpConfiguration.testRunnerTool,
                testTimeoutConfiguration: dumpConfiguration.testTimeoutConfiguration,
                testType: .appTest
            )
        }
    }

    private func simulatorForRuntimeDump(
        configuration: RuntimeDumpConfiguration
    ) throws -> AllocatedSimulator {
        let simulatorControlTool: SimulatorControlTool
        
        switch configuration.runtimeDumpMode {
        case .logicTest(let tool):
            simulatorControlTool = tool
        case .appTest(let runtimeDumpApplicationTestSupport):
            simulatorControlTool = runtimeDumpApplicationTestSupport.simulatorControlTool
        }
        
        let simulatorPool = try onDemandSimulatorPool.pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: configuration.developerDir,
                testDestination: configuration.testDestination,
                testRunnerTool: configuration.testRunnerTool,
                simulatorControlTool: simulatorControlTool
            )
        )
        return try simulatorPool.allocateSimulator()
    }
    
    private func requestedTestsNotAvailableInRuntime(
        testsInRuntimeDump: TestsInRuntimeDump,
        configuration: RuntimeDumpConfiguration) -> [TestToRun]
    {
        if configuration.testsToValidate.isEmpty { return [] }
        if testsInRuntimeDump.tests.isEmpty { return configuration.testsToValidate }
        
        let availableTestEntries = testsInRuntimeDump.tests.flatMap { runtimeDetectedTestEntry -> [TestEntry] in
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
            case .allProvidedByRuntimeDump:
                return false
            }
        }
        return testsToRunMissingInRuntime
    }
    
    private func reportStats(testCaseCount: Int, testCount: Int, configuration: RuntimeDumpConfiguration) {
        let testBundleName = configuration.xcTestBundleLocation.resourceLocation.stringValue.lastPathComponent
        Logger.info("Runtime dump of \(configuration.xcTestBundleLocation.resourceLocation): bundle has \(testCaseCount) XCTestCases, \(testCount) tests")
        MetricRecorder.capture(
            RuntimeDumpTestCountMetric(testBundleName: testBundleName, numberOfTests: testCount),
            RuntimeDumpTestCaseCountMetric(testBundleName: testBundleName, numberOfTestCases: testCaseCount)
        )
    }
    
    private func environment(
        configuration: RuntimeDumpConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> [String: String] {
        var environment = configuration.testExecutionBehavior.environment
        environment["EMCEE_RUNTIME_TESTS_EXPORT_PATH"] = runtimeEntriesJSONPath.pathString
        return environment
    }
}
