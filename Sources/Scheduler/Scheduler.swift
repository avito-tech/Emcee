import EmceeDI
import DateProvider
import DeveloperDirLocator
import Dispatch
import DistWorkerModels
import FileSystem
import Foundation
import ListeningSemaphore
import LocalHostDeterminer
import EmceeLogging
import Metrics
import MetricsExtensions
import PluginManager
import ProcessController
import QueueModels
import ResourceLocationResolver
import Runner
import RunnerModels
import ScheduleStrategy
import SimulatorPool
import SimulatorPoolModels
import SynchronousWaiter
import Tmp
import UniqueIdentifierGenerator

public final class Scheduler {
    private let di: DI
    private let dateProvider: DateProvider
    private let fileSystem: FileSystem
    private let rootLogger: ContextualLogger
    private let queue = OperationQueue()
    private let resourceLocationResolver: ResourceLocationResolver
    private let resourceSemaphore: ListeningSemaphore<ResourceAmounts>
    private let tempFolder: TemporaryFolder
    private let version: Version
    private let workerConfiguration: WorkerConfiguration
    private weak var schedulerDataSource: SchedulerDataSource?
    private weak var schedulerDelegate: SchedulerDelegate?
    
    public init(
        di: DI,
        dateProvider: DateProvider,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        resourceLocationResolver: ResourceLocationResolver,
        schedulerDataSource: SchedulerDataSource,
        schedulerDelegate: SchedulerDelegate,
        tempFolder: TemporaryFolder,
        version: Version,
        workerConfiguration: WorkerConfiguration
    ) {
        self.di = di
        self.dateProvider = dateProvider
        self.fileSystem = fileSystem
        self.rootLogger = logger
        self.resourceLocationResolver = resourceLocationResolver
        self.resourceSemaphore = ListeningSemaphore(
            maximumValues: .of(
                runningTests: Int(workerConfiguration.numberOfSimulators)
            )
        )
        self.schedulerDataSource = schedulerDataSource
        self.schedulerDelegate = schedulerDelegate
        self.tempFolder = tempFolder
        self.version = version
        self.workerConfiguration = workerConfiguration
    }
    
    public func run() throws {
        startFetchingAndRunningTests()
        
        try SynchronousWaiter().waitWhile(pollPeriod: 1.0) {
            queue.operationCount > 0
        }
    }
    
    // MARK: - Running on Queue
    
    private func startFetchingAndRunningTests() {
        for _ in 0 ..< resourceSemaphore.availableResources.runningTests {
            fetchAndRunBucket()
        }
    }
    
    private func fetchAndRunBucket() {
        queue.addOperation {
            if self.resourceSemaphore.availableResources.runningTests == 0 {
                return
            }
            guard let bucket = self.schedulerDataSource?.nextBucket() else {
                self.rootLogger.trace("Data Source returned no bucket. Will stop polling for new buckets.")
                return
            }
            let logger = self.rootLogger.with(
                analyticsConfiguration: bucket.analyticsConfiguration
            )
            logger.debug("Data Source returned bucket: \(bucket)")
            
            self.resourceLocationResolver.evictOldCache(
                cacheElementTimeToLive: self.workerConfiguration.maximumCacheTTL,
                maximumCacheSize: self.workerConfiguration.maximumCacheSize
            )
            
            self.runFetchedBucket(bucket: bucket, logger: logger)
        }
    }
    
    private func runFetchedBucket(
        bucket: SchedulerBucket,
        logger: ContextualLogger
    ) {
        do {
            let acquireResources = try resourceSemaphore.acquire(.of(runningTests: 1))
            let runTestsInBucketAfterAcquiringResources = BlockOperation { [weak self] in
                guard let strongSelf = self else {
                    return logger.error("`self` died unexpectedly")
                }
                
                do {
                    let bucketResult: BucketResult
                    switch bucket.bucketPayloadContainer {
                    case .runAppleTests(let runAppleTestsPayload):
                        bucketResult = try strongSelf.createRunAppleTestsPayloadExecutor().execute(
                            analyticsConfiguration: bucket.analyticsConfiguration,
                            bucketId: bucket.bucketId,
                            logger: logger,
                            payload: runAppleTestsPayload
                        )
                    case .runAndroidTests(let runAndroidTestsPayload):
                        bucketResult = try strongSelf.createRunAndroidTestsPayloadExecutor().execute(
                            analyticsConfiguration: bucket.analyticsConfiguration,
                            bucketId: bucket.bucketId,
                            logger: logger,
                            payload: runAndroidTestsPayload
                        )
                    }
                    try strongSelf.resourceSemaphore.release(.of(runningTests: 1))
                    strongSelf.schedulerDelegate?.scheduler(
                        strongSelf,
                        obtainedBucketResult: bucketResult,
                        forBucket: bucket
                    )
                    strongSelf.fetchAndRunBucket()
                } catch {
                    logger.error("Error running tests from fetched bucket with error: \(error). Bucket: \(bucket)")
                }
            }
            acquireResources.addCascadeCancellableDependency(runTestsInBucketAfterAcquiringResources)
            queue.addOperation(runTestsInBucketAfterAcquiringResources)
        } catch {
            logger.error("Failed to run tests from bucket: \(error). Bucket: \(bucket)")
        }
    }
    
    private func createRunAppleTestsPayloadExecutor() throws -> RunAppleTestsPayloadExecutor {
        RunAppleTestsPayloadExecutor(
            dateProvider: try di.get(),
            globalMetricRecorder: try di.get(),
            onDemandSimulatorPool: try di.get(),
            runnerProvider: try di.get(),
            simulatorSettingsModifier: try di.get(),
            specificMetricRecorderProvider: try di.get(),
            tempFolder: tempFolder,
            version: version
        )
    }
    
    private func runBucketOnce(
        analyticsConfiguration: AnalyticsConfiguration,
        runAppleTestsPayload: RunAppleTestsPayload,
        testsToRun: [TestEntry],
        logger: ContextualLogger
    ) throws -> TestingResult {
        let simulatorPool = try di.get(OnDemandSimulatorPool.self).pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: runAppleTestsPayload.developerDir,
                simDeviceType: runAppleTestsPayload.simDeviceType,
                simRuntime: runAppleTestsPayload.simRuntime
            )
        )
        
        let specificMetricRecorderProvider: SpecificMetricRecorderProvider = try di.get()
        let specificMetricRecorder = try specificMetricRecorderProvider.specificMetricRecorder(
            analyticsConfiguration: analyticsConfiguration
        )

        let allocatedSimulator = try simulatorPool.allocateSimulator(
            dateProvider: dateProvider,
            logger: logger,
            simulatorOperationTimeouts: runAppleTestsPayload.simulatorOperationTimeouts,
            version: version,
            globalMetricRecorder: try di.get()
        )
        defer { allocatedSimulator.releaseSimulator() }
        
        try di.get(SimulatorSettingsModifier.self).apply(
            developerDir: runAppleTestsPayload.developerDir,
            simulatorSettings: runAppleTestsPayload.simulatorSettings,
            toSimulator: allocatedSimulator.simulator
        )
        
        let runner = AppleRunner(
            dateProvider: dateProvider,
            developerDirLocator: try di.get(),
            fileSystem: fileSystem,
            logger: logger,
            pluginEventBusProvider: try di.get(),
            runnerWasteCollectorProvider: try di.get(),
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: tempFolder,
            testRunnerProvider: try di.get(),
            uniqueIdentifierGenerator: try di.get(),
            version: version,
            waiter: try di.get()
        )

        let runnerResult = try runner.runOnce(
            entriesToRun: testsToRun,
            configuration: AppleRunnerConfiguration(
                buildArtifacts: runAppleTestsPayload.buildArtifacts,
                developerDir:runAppleTestsPayload.developerDir,
                environment: runAppleTestsPayload.testExecutionBehavior.environment,
                logCapturingMode: runAppleTestsPayload.testExecutionBehavior.logCapturingMode,
                userInsertedLibraries: runAppleTestsPayload.testExecutionBehavior.userInsertedLibraries,
                lostTestProcessingMode: .reportError,
                persistentMetricsJobId: analyticsConfiguration.persistentMetricsJobId,
                pluginLocations: runAppleTestsPayload.pluginLocations,
                simulator: allocatedSimulator.simulator,
                simulatorSettings: runAppleTestsPayload.simulatorSettings,
                testTimeoutConfiguration: runAppleTestsPayload.testTimeoutConfiguration,
                testAttachmentLifetime: runAppleTestsPayload.testAttachmentLifetime
            )
        )
        
        cleanup(
            runnerWasteCleanupPolicy: runAppleTestsPayload.testExecutionBehavior.runnerWasteCleanupPolicy,
            runnerWasteCollector: runnerResult.runnerWasteCollector,
            logger: logger
        )
        
        runnerResult.testEntryResults.filter { $0.isLost }.forEach {
            logger.debug("Lost result for \($0)")
        }
        
        return TestingResult(
            testDestination: runAppleTestsPayload.testDestination,
            unfilteredResults: runnerResult.testEntryResults
        )
    }
    
    private func cleanup(
        runnerWasteCleanupPolicy: RunnerWasteCleanupPolicy,
        runnerWasteCollector: RunnerWasteCollector,
        logger: ContextualLogger
    ) {
        let wasteCleaner: RunnerWasteCleaner
        switch runnerWasteCleanupPolicy {
        case .keep:
            wasteCleaner = NoOpRunnerWasteCleaner(logger: logger)
        case .clean:
            wasteCleaner = RunnerWasteCleanerImpl(fileSystem: fileSystem, logger: logger)
        }
        wasteCleaner.cleanWaste(runnerWasteCollector: runnerWasteCollector)
    }
    
    // MARK: - Utility Methods
    
    /**
     Combines several TestingResult objects of the same Bucket, after running and retrying tests,
     so if some tests become green, the resulting combined object will have it in a green state.
     */
    private func combine(runResults: [TestingResult]) throws -> TestingResult {
        // All successful tests should be merged into a single array.
        // Last run's `failedTests` contains all tests that failed after all attempts to rerun failed tests.
        try TestingResult.byMerging(testingResults: runResults)
    }

    private func createRunAndroidTestsPayloadExecutor() throws -> RunAndroidTestsPayloadExecutor {
        RunAndroidTestsPayloadExecutor(
            dateProvider: try di.get()
        )
    }
}
