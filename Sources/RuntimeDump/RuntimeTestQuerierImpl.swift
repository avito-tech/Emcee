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
    private let eventBus: EventBus
    private let testQueryEntry = TestEntry(testName: TestName(className: "NonExistingTest", methodName: "fakeTest"), tags: [], caseId: nil)
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let numberOfAttemptsToPerformRuntimeDump: UInt
    
    public init(
        eventBus: EventBus,
        numberOfAttemptsToPerformRuntimeDump: UInt,
        resourceLocationResolver: ResourceLocationResolver,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator(),
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider
    ) {
        self.eventBus = eventBus
        self.numberOfAttemptsToPerformRuntimeDump = max(numberOfAttemptsToPerformRuntimeDump, 1)
        self.resourceLocationResolver = resourceLocationResolver
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
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
            eventBus: eventBus,
            configuration: runnerConfiguration,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            resourceLocationResolver: resourceLocationResolver
        )
        let runnerRunResult = try runner.runOnce(
            entriesToRun: [testQueryEntry],
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
        let environment = self.environment(runtimeEntriesJSONPath: runtimeEntriesJSONPath)
        
        if let applicationTestSupport = dumpConfiguration.applicationTestSupport {
            return RunnerConfiguration(
                testType: .appTest,
                testRunnerTool: dumpConfiguration.testRunnerTool,
                buildArtifacts: BuildArtifacts(
                    appBundle: applicationTestSupport.appBundle,
                    runner: nil,
                    xcTestBundle: dumpConfiguration.xcTestBundle,
                    additionalApplicationBundles: []
                ),
                environment: environment,
                simulatorSettings: simulatorSettings,
                testTimeoutConfiguration: dumpConfiguration.testTimeoutConfiguration
            )
        } else {
            return RunnerConfiguration(
                testType: .logicTest,
                testRunnerTool: dumpConfiguration.testRunnerTool,
                buildArtifacts: BuildArtifacts.onlyWithXctestBundle(xcTestBundle: dumpConfiguration.xcTestBundle),
                environment: environment,
                simulatorSettings: simulatorSettings,
                testTimeoutConfiguration: dumpConfiguration.testTimeoutConfiguration
            )
        }
    }

    private func simulatorForRuntimeDump(configuration: RuntimeDumpConfiguration) throws -> AllocatedSimulator {
        if let applicationTestSupport = configuration.applicationTestSupport {
            let simulatorPool = try onDemandSimulatorPool.pool(
                key: OnDemandSimulatorPool.Key(
                    numberOfSimulators: 1,
                    developerDir: configuration.developerDir,
                    testDestination: configuration.testDestination,
                    simulatorControlTool: applicationTestSupport.simulatorControlTool
                )
            )

            return try simulatorPool.allocateSimulator()
        } else {
            return AllocatedSimulator(
                simulator: Shimulator.shimulator(
                    testDestination: configuration.testDestination,
                    workingDirectory: try tempFolder.pathByCreatingDirectories(components: ["shimulator"])
                ),
                releaseSimulator: {}
            )
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
        let testBundleName = configuration.xcTestBundle.location.resourceLocation.stringValue.lastPathComponent
        Logger.info("Runtime dump contains \(testCaseCount) XCTestCases, \(testCount) tests")
        MetricRecorder.capture(
            RuntimeDumpTestCountMetric(testBundleName: testBundleName, numberOfTests: testCount),
            RuntimeDumpTestCaseCountMetric(testBundleName: testBundleName, numberOfTestCases: testCaseCount)
        )
    }
    
    private func environment(runtimeEntriesJSONPath: AbsolutePath) -> [String: String] {
        var environment = ProcessInfo.processInfo.environment
        environment["EMCEE_RUNTIME_TESTS_EXPORT_PATH"] = runtimeEntriesJSONPath.pathString
        return environment
    }
}
