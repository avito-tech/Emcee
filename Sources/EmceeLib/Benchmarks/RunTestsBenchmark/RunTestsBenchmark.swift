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
import Types
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
    public let testEntryResults: [TestEntryResult]
    
    public init(testEntryResults: [TestEntryResult]) {
        self.testEntryResults = testEntryResults
    }

    public func toCsv() -> String {
        struct _TestRunResult {
            let testName: String
            let success: Bool
            let duration: Double
        }

        var results = [_TestRunResult]()

        for testEntryResult in testEntryResults {
            for testRunResult in testEntryResult.testRunResults {
                results.append(
                    _TestRunResult(
                        testName: testEntryResult.testEntry.testName.stringValue,
                        success: testRunResult.succeeded,
                        duration: testRunResult.duration
                    )
                )
            }
        }

        var report = [String]()

        report.append(
            MultipleBenchmarkResult(
                results: results.map {
                    MappedBenchmarkResult(
                        results: [
                            "testName": $0.testName,
                            "success": $0.success,
                            "duration": $0.duration,
                        ]
                    )
                }
            ).toCsv()
        )

//        var testRunsByTestName = MapWithCollection<String, _TestRunResult>()
//        for testRun in results {
//            print("Appending to \(testRun.testName)... has \(testRunsByTestName[testRun.testName].count) points")
//            testRunsByTestName.append(key: testRun.testName, element: testRun)
//        }
//
//        print(testRunsByTestName.asDictionary)
//
//        for keyValue in testRunsByTestName.asDictionary {
//            let testName = keyValue.key
//            let testResults = keyValue.value
//
//            report.append("Test run stats for \(testName):")
//            report.append("   - \(testResults.count) total runs")
//            report.append("   - \(testResults.filter { $0.success }.count) successes")
//            report.append("   - \(testResults.filter { !$0.success }.count) failures")
//            report.append("   - min duration: \(testResults.map { $0.duration }.min() ?? 0.0)")
//            report.append("   - p50 duration: \(testResults.map { $0.duration }.percentile(probability: 0.50) ?? 0.0)")
//            report.append("   - p75 duration: \(testResults.map { $0.duration }.percentile(probability: 0.75) ?? 0.0)")
//            report.append("   - p90 duration: \(testResults.map { $0.duration }.percentile(probability: 0.90) ?? 0.0)")
//            report.append("   - p99 duration: \(testResults.map { $0.duration }.percentile(probability: 0.99) ?? 0.0)")
//            report.append("   - max duration: \(testResults.map { $0.duration }.max() ?? 0.0)")
//        }

        return report.joined(separator: "\n")
    }
}


private extension Array where Element == Double {
    func percentile(probability: Double) -> Double? {
        if probability < 0 || probability > 1 { return nil }
        let data = self.sorted(by: <)
        let count = Double(data.count)
        let m = 1.0 - probability
        let k = Int((probability * count) + m)
        let probability = (probability * count) + m - Double(k)
        return qDef(data, k: k, probability: probability)
    }

    private func qDef(_ data: [Double], k: Int, probability: Double) -> Double? {
        if data.isEmpty { return nil }
        if k < 1 { return data[0] }
        if k >= data.count { return data.last }
        return ((1.0 - probability) * data[k - 1]) + (probability * data[k])
    }
}
