import AtomicModels
import ArgLib
import Benchmarking
import DateProvider
import DI
import EmceeLogging
import EmceeVersion
import MetricsExtensions
import Foundation
import PathLib
import PlistLib
import QueueModels
import ScheduleStrategy
import SimulatorPool
import SimulatorPoolModels
import TestDiscovery
import Types
import Tmp
import TestArgFile

public final class BenchmarkCommand: Command {
    public let name = "benchmark"
    public let description = "Runs benchmarks on local machine"
    public let arguments: Arguments = [
        ArgumentDescriptions.testArgFile.asRequired,
        ArgumentDescriptions.numberOfSimulators.asRequired,
        ArgumentDescriptions.duration.asOptional,
        ArgumentDescriptions.sampleInterval.asOptional,
    ]
    
    private let di: DI
    private let logger: ContextualLogger
    private let measurer: Measurer

    public init(di: DI) throws {
        self.di = di
        
        self.di.set(try TemporaryFolder(), for: TemporaryFolder.self)
        
        self.logger = try di.get()
        self.measurer = MeasurerImpl(dateProvider: try di.get())
    }
    
    public func run(payload: CommandPayload) throws {
        let testArgFile = try ArgumentsReader.testArgFile(
            try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.testArgFile.name)
        )
        let numberOfSimulators: UInt = try payload.expectedSingleTypedValue(
            argumentName: ArgumentDescriptions.numberOfSimulators.name
        )
        let duration: Int = try payload.optionalSingleTypedValue(
            argumentName: ArgumentDescriptions.duration.name
        ) ?? 1200
        let sampleInterval: Int = try payload.optionalSingleTypedValue(
            argumentName: ArgumentDescriptions.sampleInterval.name
        ) ?? 20
        
        try executeBenchmarks(
            testArgFile: testArgFile,
            numberOfSimulators: numberOfSimulators,
            duration: duration,
            sampleInterval: sampleInterval
        )
    }
    
    private func executeBenchmarks(
        testArgFile: TestArgFile,
        numberOfSimulators: UInt,
        duration: Int,
        sampleInterval: Int
    ) throws {
        let dateProvider: DateProvider = try di.get()
        let startDate = dateProvider.currentDate()
        
        let testEntriesValidator = TestEntriesValidator(
            remoteCache: NoOpRuntimeDumpRemoteCache(),
            testArgFileEntries: testArgFile.entries,
            testDiscoveryQuerier: try di.get(),
            analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration
        )
        let bucketGenerator = BucketGeneratorImpl(
            uniqueIdentifierGenerator: try di.get()
        )
        
        let shouldKeepBenchmarksRunning: () -> Bool = {
            dateProvider.currentDate().timeIntervalSince(startDate) < TimeInterval(duration)
        }

        var benchmarks = [Benchmark]()

        _ = try testEntriesValidator.validatedTestEntries(logger: logger) { testArgFileEntry, validatedTestEntry in
            let testEntryConfigurationGenerator = TestEntryConfigurationGenerator(
                analyticsConfiguration: testArgFile.prioritizedJob.analyticsConfiguration,
                validatedEntries: validatedTestEntry,
                testArgFileEntry: testArgFileEntry,
                logger: logger
            )
            let testEntryConfigurations = testEntryConfigurationGenerator.createTestEntryConfigurations()
            let buckets = bucketGenerator.generateBuckets(
                testEntryConfigurations: testEntryConfigurations,
                splitInfo: BucketSplitInfo(numberOfWorkers: 1, numberOfParallelBuckets: numberOfSimulators),
                testSplitter: testArgFileEntry.scheduleStrategy.testSplitter
            )
            
            let benchmarksForBuckets = try buckets.map {
                try runTestBenchmark(bucket: $0)
            }
            benchmarks.append(contentsOf: benchmarksForBuckets)
        }
        
        let metricsBenchmark = ConditionallyRepeatedBenchmark(
            benchmarkToExecute: MetricsBenchmark(
                processControllerProvider: try di.get(),
                timestampProvider: TimestampProviderImpl(dateProvider: try di.get())
            ),
            condition: {
                Thread.sleep(forTimeInterval: TimeInterval(sampleInterval))
                return shouldKeepBenchmarksRunning()
            }
        )
        
        let testRunningBenchmark = ConcurrentlyRepeatedBenchmark(
            benchmarkToExecute: ConditionallyRepeatedBenchmark(
                benchmarkToExecute: SequentiallyPerformedBenchmarks(
                    benchmarks: benchmarks
                ),
                condition: shouldKeepBenchmarksRunning
            ),
            repeatCount: Int(numberOfSimulators),
            maximumParallelExecutionCount: Int(numberOfSimulators)
        )
        
        let topLevelBenchmark = ConcurrentlyPerformedBenchmarks(
            benchmarksToExecute: [
                "metrics": metricsBenchmark,
                "testRunningBenchmark": testRunningBenchmark,
            ]
        )

        let mappedBenchmarkResult = topLevelBenchmark.run(contextualLogger: logger) as? MappedBenchmarkResult

        let metricsResult = mappedBenchmarkResult?.results["metrics"]
        if let csv = metricsResult?.toCsv() {
            logger.info("Metrics:")
            logger.info(
                [
                    "timestamp",
                    "cpuLoad",
                    "numberOfRunningProcesses",
                    "numberOfOpenedFiles",
                    "freeMemory",
                    "usedMemory",
                    "swapSizeInMb",
                    "loadAverage1min",
                    "loadAverage5min",
                    "loadAverage15min",
                    "machFactor1min",
                    "machFactor5min",
                    "machFactor15min"
                ].joined(separator: ";")
            )
            for line in csv.split(separator: "\n") {
                logger.info(String(line))
            }
        }

        let testRunningBenchmarkResults = mappedBenchmarkResult?.results["testRunningBenchmark"]
        if let csv = testRunningBenchmarkResults?.toCsv() {
            logger.info("Test results:")
            logger.info("duration;success;testname")
            for line in csv.split(separator: "\n") {
                logger.info(String(line))
            }
        }
    }
    
    private func runTestBenchmark(
        bucket: Bucket
    ) throws -> Benchmark {
        let specificMetricRecorderProvider: SpecificMetricRecorderProvider = try di.get()
        let specificMetricRecorder = try specificMetricRecorderProvider.specificMetricRecorder(
            analyticsConfiguration: bucket.analyticsConfiguration
        )
        
        return RunTestBenchmark(
            dateProvider: try di.get(),
            measurer: measurer,
            onDemandSimulatorPool: try di.get(),
            bucket: bucket,
            developerDirLocator: try di.get(),
            fileSystem: try di.get(),
            pluginEventBusProvider: try di.get(),
            runnerWasteCollectorProvider: try di.get(),
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: try di.get(),
            testRunnerProvider: try di.get(),
            uniqueIdentifierGenerator: try di.get(),
            waiter: try di.get()
        )
    }
}
