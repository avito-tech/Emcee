import DeveloperDirLocator
import EventBus
import Extensions
import Foundation
import Logging
import Metrics
import Models
import PathLib
import ResourceLocationResolver
import Runner
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator

public final class RuntimeTestQuerierImpl: RuntimeTestQuerier {
    private let developerDirLocator: DeveloperDirLocator
    private let eventBus: EventBus
    private let numberOfAttemptsToPerformRuntimeDump: UInt
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TemporaryFolder
    private let testEntryToQueryRuntimeDump: TestEntry
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    
    public init(
        eventBus: EventBus,
        developerDirLocator: DeveloperDirLocator,
        numberOfAttemptsToPerformRuntimeDump: UInt,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder,
        testEntryToQueryRuntimeDump: TestEntry = TestEntry(testName: TestName(className: "NonExistingTest", methodName: "fakeTest"), tags: [], caseId: nil),
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.eventBus = eventBus
        self.developerDirLocator = developerDirLocator
        self.numberOfAttemptsToPerformRuntimeDump = max(numberOfAttemptsToPerformRuntimeDump, 1)
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
        self.testEntryToQueryRuntimeDump = testEntryToQueryRuntimeDump
        self.testRunnerProvider = testRunnerProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func queryRuntime(configuration: RuntimeDumpConfiguration) throws -> RuntimeQueryResult {
        let availableRuntimeTests = try runRetrying(times: numberOfAttemptsToPerformRuntimeDump) {
            try availableTestsInRuntime(configuration: configuration)
        }
        let unavailableTestEntries = requestedTestsNotAvailableInRuntime(
            runtimeDetectedEntries: availableRuntimeTests,
            configuration: configuration
        )
        return RuntimeQueryResult(
            unavailableTestsToRun: unavailableTestEntries,
            availableRuntimeTests: availableRuntimeTests
        )
    }
    
    private func runRetrying<T>(times: UInt, _ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< times {
            do {
                return try work()
            } catch {
                Logger.error("Failed to get runtime dump, error: \(error)")
                SynchronousWaiter.wait(timeout: TimeInterval(retryIndex) * 2.0, description: "Pause between runtime dump retries")
            }
        }
        return try work()
    }
    
    private func availableTestsInRuntime(configuration: RuntimeDumpConfiguration) throws -> [RuntimeTestEntry] {
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
            eventBus: eventBus,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider
        )
        let runnerRunResult = try runner.runOnce(
            entriesToRun: [testEntryToQueryRuntimeDump],
            developerDir: configuration.developerDir,
            simulatorInfo: allocatedSimulator.simulator.simulatorInfo
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
        
        return foundTestEntries
    }

    private func buildRunnerConfiguration(
        dumpConfiguration: RuntimeDumpConfiguration,
        runtimeEntriesJSONPath: AbsolutePath
    ) -> RunnerConfiguration {
        let simulatorSettings = SimulatorSettings(simulatorLocalizationSettings: nil, watchdogSettings: nil)
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
                simulatorSettings: simulatorSettings,
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
                simulatorSettings: simulatorSettings,
                testRunnerTool: dumpConfiguration.testRunnerTool,
                testTimeoutConfiguration: dumpConfiguration.testTimeoutConfiguration,
                testType: .appTest
            )
        }
    }

    private func simulatorForRuntimeDump(
        configuration: RuntimeDumpConfiguration
    ) throws -> AllocatedSimulator {
        switch configuration.runtimeDumpMode {
        case .logicTest:
            return AllocatedSimulator(
                simulator: Shimulator.shimulator(
                    testDestination: configuration.testDestination,
                    workingDirectory: try tempFolder.pathByCreatingDirectories(components: ["shimulator"])
                ),
                releaseSimulator: {}
            )
        case .appTest(let runtimeDumpApplicationTestSupport):
            let simulatorPool = try onDemandSimulatorPool.pool(
                key: OnDemandSimulatorPool.Key(
                    developerDir: configuration.developerDir,
                    testDestination: configuration.testDestination,
                    simulatorControlTool: runtimeDumpApplicationTestSupport.simulatorControlTool
                )
            )
            return try simulatorPool.allocateSimulator()
        }
    }
    
    private func requestedTestsNotAvailableInRuntime(
        runtimeDetectedEntries: [RuntimeTestEntry],
        configuration: RuntimeDumpConfiguration) -> [TestToRun]
    {
        if configuration.testsToValidate.isEmpty { return [] }
        if runtimeDetectedEntries.isEmpty { return configuration.testsToValidate }
        
        let availableTestEntries = runtimeDetectedEntries.flatMap { runtimeDetectedTestEntry -> [TestEntry] in
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
        Logger.info("Runtime dump contains \(testCaseCount) XCTestCases, \(testCount) tests")
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
