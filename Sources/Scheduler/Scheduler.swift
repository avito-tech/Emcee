import EmceeDI
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
    private let dateProvider: DateProvider
    private let rootLogger: ContextualLogger
    private let queue = OperationQueue()
    private let resourceSemaphore: ListeningSemaphore<ResourceAmounts>
    private let version: Version
    private weak var schedulerDataSource: SchedulerDataSource?
    private weak var schedulerDelegate: SchedulerDelegate?
    
    public init(
        di: DI,
        dateProvider: DateProvider,
        logger: ContextualLogger,
        numberOfSimulators: UInt,
        schedulerDataSource: SchedulerDataSource,
        schedulerDelegate: SchedulerDelegate,
        version: Version
    ) {
        self.di = di
        self.dateProvider = dateProvider
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
                self.rootLogger.debug("Data Source returned no bucket")
                return
            }
            let logger = self.rootLogger.with(
                analyticsConfiguration: bucket.analyticsConfiguration
            )
            logger.debug("Data Source returned bucket: \(bucket)")
            self.runTestsFromFetchedBucket(bucket: bucket, logger: logger)
        }
    }
    
    private func runTestsFromFetchedBucket(
        bucket: SchedulerBucket,
        logger: ContextualLogger
    ) {
        do {
            let acquireResources = try resourceSemaphore.acquire(.of(runningTests: 1))
            let runTestsInBucketAfterAcquiringResources = BlockOperation {
                do {
                    let bucketResult: BucketResult
                    switch bucket.bucketPayload {
                    case .runIosTests(let runIosTestsPayload):
                        bucketResult = self.executeIosTestsBucket(
                            analyticsConfiguration: bucket.analyticsConfiguration,
                            bucketId: bucket.bucketId,
                            runIosTestsPayload: runIosTestsPayload,
                            logger: logger
                        )
                    case .ping:
                        bucketResult = self.executePing(
                            analyticsConfiguration: bucket.analyticsConfiguration,
                            bucketId: bucket.bucketId,
                            logger: logger
                        )
                    }
                    try self.resourceSemaphore.release(.of(runningTests: 1))
                    self.schedulerDelegate?.scheduler(
                        self,
                        obtainedBucketResult: bucketResult,
                        forBucket: bucket
                    )
                    self.fetchAndRunBucket()
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
    
    // MARK: - Running iOS Tests
    
    private func executeIosTestsBucket(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketId: BucketId,
        runIosTestsPayload: RunIosTestsPayload,
        logger: ContextualLogger
    ) -> BucketResult {
        let startedAt = dateProvider.dateSince1970ReferenceDate()
        let testingResult: TestingResult
        do {
            testingResult = try runRetrying(
                analyticsConfiguration: analyticsConfiguration,
                runIosTestsPayload: runIosTestsPayload,
                logger: logger,
                numberOfRetries: runIosTestsPayload.testExecutionBehavior.numberOfRetriesOnWorker()
            )
        } catch {
            logger.error("Failed to execute bucket \(bucketId): \(error)")
            testingResult = TestingResult(
                testDestination: runIosTestsPayload.testDestination,
                unfilteredResults: runIosTestsPayload.testEntries.map { testEntry -> TestEntryResult in
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
        return .testingResult(testingResult)
    }
    
    /**
     Runs tests in a given Bucket, retrying failed tests multiple times if necessary.
     */
    private func runRetrying(
        analyticsConfiguration: AnalyticsConfiguration,
        runIosTestsPayload: RunIosTestsPayload,
        logger: ContextualLogger,
        numberOfRetries: UInt
    ) throws -> TestingResult {
        let firstRun = try runBucketOnce(
            analyticsConfiguration: analyticsConfiguration,
            runIosTestsPayload: runIosTestsPayload,
            testsToRun: runIosTestsPayload.testEntries,
            logger: logger
        )
        
        guard numberOfRetries > 0 else { return firstRun }
        
        var lastRunResults = firstRun
        var results = [firstRun]
        for retryNumber in 0 ..< numberOfRetries {
            let failedTestEntriesAfterLastRun = lastRunResults.failedTests.map { $0.testEntry }
            if failedTestEntriesAfterLastRun.isEmpty {
                logger.debug("No failed tests after last retry, so nothing to run.")
                break
            }
            logger.debug("After last run \(failedTestEntriesAfterLastRun.count) tests have failed: \(failedTestEntriesAfterLastRun).")
            logger.debug("Retrying them, attempt #\(retryNumber + 1) of maximum \(numberOfRetries) attempts")
            lastRunResults = try runBucketOnce(
                analyticsConfiguration: analyticsConfiguration,
                runIosTestsPayload: runIosTestsPayload,
                testsToRun: failedTestEntriesAfterLastRun,
                logger: logger
            )
            results.append(lastRunResults)
        }
        return try TestingResult.byMerging(testingResults: results)
    }
    
    private func runBucketOnce(
        analyticsConfiguration: AnalyticsConfiguration,
        runIosTestsPayload: RunIosTestsPayload,
        testsToRun: [TestEntry],
        logger: ContextualLogger
    ) throws -> TestingResult {
        let simulatorPool = try di.get(OnDemandSimulatorPool.self).pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: runIosTestsPayload.developerDir,
                testDestination: runIosTestsPayload.testDestination
            )
        )
        
        let specificMetricRecorderProvider: SpecificMetricRecorderProvider = try di.get()
        let specificMetricRecorder = try specificMetricRecorderProvider.specificMetricRecorder(
            analyticsConfiguration: analyticsConfiguration
        )

        let allocatedSimulator = try simulatorPool.allocateSimulator(
            dateProvider: dateProvider,
            logger: logger,
            simulatorOperationTimeouts: runIosTestsPayload.simulatorOperationTimeouts,
            version: version,
            globalMetricRecorder: try di.get()
        )
        defer { allocatedSimulator.releaseSimulator() }
        
        try di.get(SimulatorSettingsModifier.self).apply(
            developerDir: runIosTestsPayload.developerDir,
            simulatorSettings: runIosTestsPayload.simulatorSettings,
            toSimulator: allocatedSimulator.simulator
        )
        
        let runner = Runner(
            dateProvider: dateProvider,
            developerDirLocator: try di.get(),
            fileSystem: try di.get(),
            logger: logger,
            pluginEventBusProvider: try di.get(),
            runnerWasteCollectorProvider: try di.get(),
            specificMetricRecorder: specificMetricRecorder,
            tempFolder: try di.get(),
            testRunnerProvider: try di.get(),
            uniqueIdentifierGenerator: try di.get(),
            version: version,
            waiter: try di.get()
        )

        let runnerResult = try runner.runOnce(
            entriesToRun: testsToRun,
            configuration: RunnerConfiguration(
                buildArtifacts: runIosTestsPayload.buildArtifacts,
                developerDir:runIosTestsPayload.developerDir,
                environment: runIosTestsPayload.testExecutionBehavior.environment,
                lostTestProcessingMode: .reportError,
                persistentMetricsJobId: analyticsConfiguration.persistentMetricsJobId,
                pluginLocations: runIosTestsPayload.pluginLocations,
                simulator: allocatedSimulator.simulator,
                simulatorSettings: runIosTestsPayload.simulatorSettings,
                testTimeoutConfiguration: runIosTestsPayload.testTimeoutConfiguration
            )
        )
        
        runnerResult.testEntryResults.filter { $0.isLost }.forEach {
            logger.debug("Lost result for \($0)")
        }
        
        return TestingResult(
            testDestination: runIosTestsPayload.testDestination,
            unfilteredResults: runnerResult.testEntryResults
        )
    }
<<<<<<< HEAD
=======
    
    // MARK: - Ping
    
    private func executePing(
        analyticsConfiguration: AnalyticsConfiguration,
        bucketId: BucketId,
        logger: ContextualLogger
    ) -> BucketResult {
        return .pong
    }
>>>>>>> 6f0a74d5 (Ping)
}
