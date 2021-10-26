import DI
import DateProvider
import DeveloperDirLocator
import Dispatch
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
    private let rootLogger: ContextualLogger
    private let queue = OperationQueue()
    private let resourceSemaphore: ListeningSemaphore<ResourceAmounts>
    private let version: Version
    private weak var schedulerDataSource: SchedulerDataSource?
    private weak var schedulerDelegate: SchedulerDelegate?
    
    public init(
        di: DI,
        logger: ContextualLogger,
        numberOfSimulators: UInt,
        schedulerDataSource: SchedulerDataSource,
        schedulerDelegate: SchedulerDelegate,
        version: Version
    ) {
        self.di = di
        self.rootLogger = logger
        self.resourceSemaphore = ListeningSemaphore(
            maximumValues: .of(
                runningTests: Int(numberOfSimulators)
            )
        )
        self.schedulerDataSource = schedulerDataSource
        self.schedulerDelegate = schedulerDelegate
        self.version = version
    }
    
    public func run() throws {
        startFetchingAndRunningTests(
            dateProvider: try di.get()
        )
        try SynchronousWaiter().waitWhile(pollPeriod: 1.0) {
            queue.operationCount > 0
        }
    }
    
    // MARK: - Running on Queue
    
    private func startFetchingAndRunningTests(
        dateProvider: DateProvider
    ) {
        for _ in 0 ..< resourceSemaphore.availableResources.runningTests {
            fetchAndRunBucket(dateProvider: dateProvider)
        }
    }
    
    private func fetchAndRunBucket(
        dateProvider: DateProvider
    ) {
        queue.addOperation {
            if self.resourceSemaphore.availableResources.runningTests == 0 {
                return
            }
            guard let bucket = self.schedulerDataSource?.nextBucket() else {
                self.rootLogger.debug("Data Source returned no bucket")
                return
            }
            let logger = self.rootLogger.with(
                analyticsConfiguration: bucket.analyticsConfiguration
            )
            logger.debug("Data Source returned bucket: \(bucket)")
            self.runTestsFromFetchedBucket(bucket: bucket, dateProvider: dateProvider, logger: logger)
        }
    }
    
    private func runTestsFromFetchedBucket(
        bucket: SchedulerBucket,
        dateProvider: DateProvider,
        logger: ContextualLogger
    ) {
        do {
            let acquireResources = try resourceSemaphore.acquire(.of(runningTests: 1))
            let runTestsInBucketAfterAcquiringResources = BlockOperation {
                do {
                    let testingResult = self.execute(bucket: bucket, dateProvider: dateProvider, logger: logger)
                    try self.resourceSemaphore.release(.of(runningTests: 1))
                    self.schedulerDelegate?.scheduler(self, obtainedTestingResult: testingResult, forBucket: bucket)
                    self.fetchAndRunBucket(dateProvider: dateProvider)
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
    
    // MARK: - Running the Tests
    
    private func execute(
        bucket: SchedulerBucket,
        dateProvider: DateProvider,
        logger: ContextualLogger
    ) -> TestingResult {
        let startedAt = dateProvider.dateSince1970ReferenceDate()
        do {
            return try runRetrying(bucket: bucket, logger: logger)
        } catch {
            logger.error("Failed to execute bucket \(bucket.bucketId): \(error)")
            return TestingResult(
                testDestination: bucket.runTestsBucketPayload.testDestination,
                unfilteredResults: bucket.runTestsBucketPayload.testEntries.map { testEntry -> TestEntryResult in
                    TestEntryResult.withResult(
                        testEntry: testEntry,
                        testRunResult: TestRunResult(
                            succeeded: false,
                            exceptions: [
                                TestException(
                                    reason: "Emcee failed to execute this test: \(error)",
                                    filePathInProject: #file,
                                    lineNumber: #line,
                                    relatedTestName: testEntry.testName
                                )
                            ],
                            logs: [],
                            duration: dateProvider.currentDate().timeIntervalSince(startedAt.date),
                            startTime: startedAt,
                            hostName: LocalHostDeterminer.currentHostAddress,
                            simulatorId: UDID(value: "undefined")
                        )
                    )
                }
            )
        }
    }
    
    /**
     Runs tests in a given Bucket, retrying failed tests multiple times if necessary.
     */
    private func runRetrying(
        bucket: SchedulerBucket,
        logger: ContextualLogger
    ) throws -> TestingResult {
        let firstRun = try runBucketOnce(
            bucket: bucket,
            testsToRun: bucket.runTestsBucketPayload.testEntries,
            logger: logger
        )
        
        guard bucket.runTestsBucketPayload.testExecutionBehavior.numberOfRetries > 0 else {
            return firstRun
        }
        
        var lastRunResults = firstRun
        var results = [firstRun]
        for retryNumber in 0 ..< bucket.runTestsBucketPayload.testExecutionBehavior.numberOfRetries {
            let failedTestEntriesAfterLastRun = lastRunResults.failedTests.map { $0.testEntry }
            if failedTestEntriesAfterLastRun.isEmpty {
                logger.debug("No failed tests after last retry, so nothing to run.")
                break
            }
            logger.debug("After last run \(failedTestEntriesAfterLastRun.count) tests have failed: \(failedTestEntriesAfterLastRun).")
            logger.debug("Retrying them, attempt #\(retryNumber + 1) of maximum \(bucket.runTestsBucketPayload.testExecutionBehavior.numberOfRetries) attempts")
            lastRunResults = try runBucketOnce(bucket: bucket, testsToRun: failedTestEntriesAfterLastRun, logger: logger)
            results.append(lastRunResults)
        }
        return try combine(runResults: results)
    }
    
    private func runBucketOnce(
        bucket: SchedulerBucket,
        testsToRun: [TestEntry],
        logger: ContextualLogger
    ) throws -> TestingResult {
        let simulatorPool = try di.get(OnDemandSimulatorPool.self).pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: bucket.runTestsBucketPayload.developerDir,
                testDestination: bucket.runTestsBucketPayload.testDestination,
                simulatorControlTool: bucket.runTestsBucketPayload.simulatorControlTool
            )
        )
        
        let specificMetricRecorderProvider: SpecificMetricRecorderProvider = try di.get()
        let specificMetricRecorder = try specificMetricRecorderProvider.specificMetricRecorder(
            analyticsConfiguration: bucket.analyticsConfiguration
        )

        let allocatedSimulator = try simulatorPool.allocateSimulator(
            dateProvider: try di.get(),
            logger: logger,
            simulatorOperationTimeouts: bucket.runTestsBucketPayload.simulatorOperationTimeouts,
            version: version,
            globalMetricRecorder: try di.get()
        )
        defer { allocatedSimulator.releaseSimulator() }
        
        try di.get(SimulatorSettingsModifier.self).apply(
            developerDir: bucket.runTestsBucketPayload.developerDir,
            simulatorSettings: bucket.runTestsBucketPayload.simulatorSettings,
            toSimulator: allocatedSimulator.simulator
        )
        
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
            dateProvider: try di.get(),
            developerDirLocator: try di.get(),
            fileSystem: try di.get(),
            logger: logger,
            persistentMetricsJobId: bucket.analyticsConfiguration.persistentMetricsJobId,
            pluginEventBusProvider: try di.get(),
            runnerWasteCollectorProvider: try di.get(),
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: try di.get(),
            testRunnerProvider: try di.get(),
            uniqueIdentifierGenerator: try di.get(),
            version: version,
            waiter: try di.get()
        )

        let runnerResult = try runner.run(
            entries: testsToRun,
            developerDir: bucket.runTestsBucketPayload.developerDir,
            simulator: allocatedSimulator.simulator
        )
        
        runnerResult.testEntryResults.filter { $0.isLost }.forEach {
            logger.debug("Lost result for \($0)")
        }
        
        return TestingResult(
            testDestination: bucket.runTestsBucketPayload.testDestination,
            unfilteredResults: runnerResult.testEntryResults
        )
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
}
