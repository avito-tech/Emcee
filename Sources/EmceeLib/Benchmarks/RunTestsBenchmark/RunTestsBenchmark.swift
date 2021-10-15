import Benchmarking
import DateProvider
import EmceeLogging
import EmceeVersion
import Foundation
import MetricsExtensions
import QueueModels
import Runner
import RunnerModels
import SimulatorPool
import SimulatorPoolModels
import DeveloperDirLocator
import FileSystem
import PlistLib
import PluginManager
import Tmp
import UniqueIdentifierGenerator
import SynchronousWaiter

public final class RunTestBenchmark: Benchmark {
    private let dateProvider: DateProvider
    private let measurer: Measurer
    private let onDemandSimulatorPool: OnDemandSimulatorPool
    private let simulatorOperationTimeouts = SimulatorOperationTimeouts(
        create: 180,
        boot: 600,
        delete: 300,
        shutdown: 300,
        automaticSimulatorShutdown: 9999,
        automaticSimulatorDelete: 9999
    )
    private let bucket: Bucket
    private let emceeVersion = EmceeVersion.version
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let pluginEventBusProvider: PluginEventBusProvider
    private let runnerWasteCollectorProvider: RunnerWasteCollectorProvider
    private let specificMetricRecorder: SpecificMetricRecorder
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let waiter: Waiter
    
    public var name: String {
        "Run test benchmark"
    }
    
    public init(
        dateProvider: DateProvider,
        measurer: Measurer,
        onDemandSimulatorPool: OnDemandSimulatorPool,
        bucket: Bucket,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        pluginEventBusProvider: PluginEventBusProvider,
        runnerWasteCollectorProvider: RunnerWasteCollectorProvider,
        specificMetricRecorder: SpecificMetricRecorder,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        waiter: Waiter
    ) {
        self.dateProvider = dateProvider
        self.measurer = measurer
        self.onDemandSimulatorPool = onDemandSimulatorPool
        self.bucket = bucket
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.pluginEventBusProvider = pluginEventBusProvider
        self.runnerWasteCollectorProvider = runnerWasteCollectorProvider
        self.specificMetricRecorder = specificMetricRecorder
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.waiter = waiter
    }
    
    public func run(contextualLogger: ContextualLogger) -> BenchmarkResult {
        do {
            let simulatorPool = try onDemandSimulatorPool.pool(
                key: OnDemandSimulatorPoolKey(
                    developerDir: bucket.runTestsBucketPayload.developerDir,
                    testDestination: bucket.runTestsBucketPayload.testDestination,
                    simulatorControlTool: bucket.runTestsBucketPayload.simulatorControlTool
                )
            )
            
            let simulatorController = try simulatorPool.allocateSimulator(
                dateProvider: dateProvider,
                logger: contextualLogger,
                simulatorOperationTimeouts: simulatorOperationTimeouts,
                version: emceeVersion,
                globalMetricRecorder: GlobalMetricRecorderImpl()
            )
            defer {
                simulatorController.releaseSimulator()
            }
            
            return try run(
                contextualLogger: contextualLogger,
                simulator: simulatorController.simulator
            )
        } catch {
            return ErrorBenchmarkResult(error: error)
        }
    }
    
    private func run(
        contextualLogger: ContextualLogger,
        simulator: Simulator
    ) throws -> BenchmarkResult {
        contextualLogger.info("Running \(bucket.runTestsBucketPayload.testEntries.count) tests on \(simulator.udid.value)")
        
        let runner = Runner(
            configuration: RunnerConfiguration(
                buildArtifacts: bucket.runTestsBucketPayload.buildArtifacts,
                environment: bucket.runTestsBucketPayload.testExecutionBehavior.environment,
                pluginLocations: bucket.pluginLocations,
                simulatorSettings: bucket.runTestsBucketPayload.simulatorSettings,
                testRunnerTool: bucket.runTestsBucketPayload.testRunnerTool,
                testTimeoutConfiguration: bucket.runTestsBucketPayload.testTimeoutConfiguration,
                testType: bucket.runTestsBucketPayload.testType
            ),
            dateProvider: dateProvider,
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            logger: contextualLogger,
            persistentMetricsJobId: bucket.analyticsConfiguration.persistentMetricsJobId,
            pluginEventBusProvider: pluginEventBusProvider,
            runnerWasteCollectorProvider: runnerWasteCollectorProvider,
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            version: emceeVersion,
            waiter: waiter
        )
        
        let testEntryResults = try runner.runOnce(
            entriesToRun: bucket.runTestsBucketPayload.testEntries,
            developerDir: bucket.runTestsBucketPayload.developerDir,
            simulator: simulator,
            lostTestProcessingMode: .reportError
        ).testEntryResults
        
        return RunTestBenchmarkResult(testEntryResults: testEntryResults)
    }
}

public struct RunTestBenchmarkResult: BenchmarkResult {
    private let testEntryResults: [TestEntryResult]
    
    public init(testEntryResults: [TestEntryResult]) {
        self.testEntryResults = testEntryResults
    }
    
    public func plistEntry() -> PlistEntry {
        .array(
            testEntryResults.map { testEntryResult in
                PlistEntry.dict([
                    "testName": .string(testEntryResult.testEntry.testName.stringValue),
                    "succeeded": .bool(testEntryResult.succeeded),
                    "testRunResults": .array(
                        testEntryResult.testRunResults.map {
                            PlistEntry.dict([
                                "duration": .number($0.duration),
                                "succeeded": .bool($0.succeeded),
                                "udid": .string($0.simulatorId.value),
                                "exceptions": .array(
                                    $0.exceptions.map { PlistEntry.string($0.reason) }
                                ),
                            ])
                        }
                    )
                ])
            }
        )
    }
}
