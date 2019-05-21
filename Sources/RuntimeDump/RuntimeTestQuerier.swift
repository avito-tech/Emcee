import EventBus
import Extensions
import Foundation
import Logging
import Metrics
import Models
import ResourceLocationResolver
import Runner
import SimulatorPool
import SynchronousWaiter
import TempFolder
import Basic

public final class RuntimeTestQuerier {
    private let eventBus: EventBus
    private let configuration: RuntimeDumpConfiguration
    private let testQueryEntry = TestEntry(className: "NonExistingTest", methodName: "fakeTest", caseId: nil)
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TempFolder
    private let onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>
    static let runtimeTestsJsonFilename = "runtime_tests.json"
    
    public init(
        eventBus: EventBus,
        configuration: RuntimeDumpConfiguration,
        resourceLocationResolver: ResourceLocationResolver,
        onDemandSimulatorPool: OnDemandSimulatorPool<DefaultSimulatorController>,
        tempFolder: TempFolder)
    {
        self.eventBus = eventBus
        self.configuration = configuration
        self.resourceLocationResolver = resourceLocationResolver
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.tempFolder = tempFolder
    }
    
    public func queryRuntime() throws -> RuntimeQueryResult {
        let availableRuntimeTests = try runRetrying(times: 5) { try availableTestsInRuntime() }
        let unavailableTestEntries = requestedTestsNotAvailableInRuntime(availableRuntimeTests)
        return RuntimeQueryResult(
            unavailableTestsToRun: unavailableTestEntries,
            availableRuntimeTests: availableRuntimeTests
        )
    }
    
    private func runRetrying<T>(times: Int, _ work: () throws -> T) rethrows -> T {
        for retryIndex in 0 ..< times {
            do {
                return try work()
            } catch {
                Logger.error("Failed to get runtime dump, error: \(error)")
                SynchronousWaiter.wait(timeout: TimeInterval(retryIndex) * 2.0)
            }
        }
        return try work()
    }
    
    private func availableTestsInRuntime() throws -> [RuntimeTestEntry] {
        let runtimeEntriesJSONPath = tempFolder.pathWith(components: [RuntimeTestQuerier.runtimeTestsJsonFilename])
        Logger.debug("Will dump runtime tests into file: \(runtimeEntriesJSONPath)")

        let simulator = try simulatorForRuntimeDump(dumpConfiguration: configuration)
        let runnerConfiguration = buildRunnerConfiguration(
            dumpConfiguration: configuration,
            runtimeEntriesJSONPath: runtimeEntriesJSONPath
        )
        let runner = Runner(
            eventBus: eventBus,
            configuration: runnerConfiguration,
            tempFolder: tempFolder,
            resourceLocationResolver: resourceLocationResolver
        )
        _ = try runner.runOnce(
            entriesToRun: [testQueryEntry],
            simulator: simulator
        )
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: runtimeEntriesJSONPath.pathString)),
            let foundTestEntries = try? JSONDecoder().decode([RuntimeTestEntry].self, from: data) else {
                throw TestExplorationError.fileNotFound(runtimeEntriesJSONPath.pathString)
        }
        
        let allTests = foundTestEntries.flatMap { $0.testMethods }
        reportStats(testCaseCount: foundTestEntries.count, testCount: allTests.count)
        
        return foundTestEntries
    }

    private func buildRunnerConfiguration(
        dumpConfiguration: RuntimeDumpConfiguration,
        runtimeEntriesJSONPath: AbsolutePath) -> RunnerConfiguration
    {
        if let applicationTestSupport = dumpConfiguration.applicationTestSupport {
            return RunnerConfiguration(
                testType: .appTest,
                fbxctest: dumpConfiguration.fbxctest,
                buildArtifacts: BuildArtifacts(
                    appBundle: applicationTestSupport.appBundle,
                    runner: nil,
                    xcTestBundle: dumpConfiguration.xcTestBundle,
                    additionalApplicationBundles: []
                ),
                environment: ["AVITO_TEST_RUNNER_RUNTIME_TESTS_EXPORT_PATH": runtimeEntriesJSONPath.pathString],
                simulatorSettings: SimulatorSettings(simulatorLocalizationSettings: nil, watchdogSettings: nil),
                testTimeoutConfiguration: dumpConfiguration.testTimeoutConfiguration
            )
        } else {
            return RunnerConfiguration(
                testType: .logicTest,
                fbxctest: dumpConfiguration.fbxctest,
                buildArtifacts: BuildArtifacts.onlyWithXctestBundle(xcTestBundle: dumpConfiguration.xcTestBundle),
                environment: ["AVITO_TEST_RUNNER_RUNTIME_TESTS_EXPORT_PATH": runtimeEntriesJSONPath.pathString],
                simulatorSettings: SimulatorSettings(simulatorLocalizationSettings: nil, watchdogSettings: nil),
                testTimeoutConfiguration: dumpConfiguration.testTimeoutConfiguration
            )
        }
    }

    private func simulatorForRuntimeDump(dumpConfiguration: RuntimeDumpConfiguration) throws -> Simulator {
        if let applicationTestSupport = dumpConfiguration.applicationTestSupport {
            let simulatorPool = try onDemandSimulatorPool.pool(
                key: OnDemandSimulatorPool.Key(
                    numberOfSimulators: 1,
                    testDestination: configuration.testDestination,
                    fbsimctl: applicationTestSupport.fbsimctl
                )
            )

            let simulatorController = try simulatorPool.allocateSimulatorController()
            defer { simulatorPool.freeSimulatorController(simulatorController) }

            do {
                return try simulatorController.bootedSimulator()
            } catch {
                Logger.error("Failed to get booted simulator: \(error)")
                try simulatorController.deleteSimulator()
                throw error
            }
        } else {
            return Shimulator.shimulator(
                testDestination: configuration.testDestination,
                workingDirectory: try tempFolder.pathByCreatingDirectories(components: ["shimulator"])
            )
        }
    }
    
    private func requestedTestsNotAvailableInRuntime(_ runtimeDetectedEntries: [RuntimeTestEntry]) -> [TestToRun] {
        if configuration.testsToRun.isEmpty { return [] }
        if runtimeDetectedEntries.isEmpty { return configuration.testsToRun }
        
        let availableTestEntries = runtimeDetectedEntries.flatMap { runtimeDetectedTestEntry -> [TestEntry] in
            runtimeDetectedTestEntry.testMethods.map {
                TestEntry(className: runtimeDetectedTestEntry.className, methodName: $0, caseId: runtimeDetectedTestEntry.caseId)
            }
        }
        let testsToRunMissingInRuntime = configuration.testsToRun.filter { requestedTestToRun -> Bool in
            switch requestedTestToRun {
            case .testName(let requestedTestName):
                return availableTestEntries.first { $0.testName == requestedTestName } == nil
            }
        }
        return testsToRunMissingInRuntime
    }
    
    private func reportStats(testCaseCount: Int, testCount: Int) {
        let testBundleName = configuration.xcTestBundle.resourceLocation.stringValue.lastPathComponent
        Logger.info("Runtime dump contains \(testCaseCount) XCTestCases, \(testCount) tests")
        MetricRecorder.capture(
            RuntimeDumpTestCountMetric(testBundleName: testBundleName, numberOfTests: testCount),
            RuntimeDumpTestCaseCountMetric(testBundleName: testBundleName, numberOfTestCases: testCaseCount)
        )
    }
}
