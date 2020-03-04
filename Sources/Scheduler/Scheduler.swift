import DeveloperDirLocator
import Dispatch
import Extensions
import Foundation
import LocalHostDeterminer
import ListeningSemaphore
import Logging
import Models
import PluginManager
import ResourceLocationResolver
import Runner
import RunnerModels
import ScheduleStrategy
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff

public final class Scheduler {
    private let configuration: SchedulerConfiguration
    private let developerDirLocator: DeveloperDirLocator
    private let queue = OperationQueue()
    private let pluginEventBusProvider: PluginEventBusProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let resourceSemaphore: ListeningSemaphore<ResourceAmounts>
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private weak var schedulerDelegate: SchedulerDelegate?
    
    public init(
        configuration: SchedulerConfiguration,
        developerDirLocator: DeveloperDirLocator,
        pluginEventBusProvider: PluginEventBusProvider,
        resourceLocationResolver: ResourceLocationResolver,
        schedulerDelegate: SchedulerDelegate?,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider
    ) {
        self.configuration = configuration
        self.developerDirLocator = developerDirLocator
        self.pluginEventBusProvider = pluginEventBusProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.resourceSemaphore = ListeningSemaphore(
            maximumValues: .of(
                runningTests: Int(configuration.numberOfSimulators)
            )
        )
        self.schedulerDelegate = schedulerDelegate
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
    }
    
    public func run() throws {
        startFetchingAndRunningTests()
        try SynchronousWaiter().waitWhile(pollPeriod: 1.0) {
            queue.operationCount > 0
        }
    }
    
    // MARK: - Running on Queue
    
    private func startFetchingAndRunningTests() {
        for _ in 0 ..< configuration.numberOfSimulators {
            fetchAndRunBucket()
        }
    }
    
    private func fetchAndRunBucket() {
        queue.addOperation {
            if self.resourceSemaphore.availableResources.runningTests == 0 {
                return
            }
            guard let bucket = self.configuration.schedulerDataSource.nextBucket() else {
                Logger.debug("Data Source returned no bucket")
                return
            }
            Logger.debug("Data Source returned bucket: \(bucket)")
            self.runTestsFromFetchedBucket(bucket)
        }
    }
    
    private func runTestsFromFetchedBucket(_ bucket: SchedulerBucket) {
        do {
            let acquireResources = try resourceSemaphore.acquire(.of(runningTests: 1))
            let runTestsInBucketAfterAcquiringResources = BlockOperation {
                do {
                    let testingResult = self.execute(bucket: bucket)
                    try self.resourceSemaphore.release(.of(runningTests: 1))
                    self.schedulerDelegate?.scheduler(self, obtainedTestingResult: testingResult, forBucket: bucket)
                    self.fetchAndRunBucket()
                } catch {
                    Logger.error("Error running tests from fetched bucket '\(bucket)' with error: \(error)")
                }
            }
            acquireResources.addCascadeCancellableDependency(runTestsInBucketAfterAcquiringResources)
            queue.addOperation(runTestsInBucketAfterAcquiringResources)
        } catch {
            Logger.error("Failed to run tests from bucket \(bucket): \(error)")
        }
    }
    
    // MARK: - Running the Tests
    
    private func execute(bucket: SchedulerBucket) -> TestingResult {
        let startedAt = Date()
        do {
            return try self.runRetrying(bucket: bucket)
        } catch {
            Logger.error("Failed to execute bucket \(bucket.bucketId): \(error)")
            return TestingResult(
                bucketId: bucket.bucketId,
                testDestination: bucket.testDestination,
                unfilteredResults: bucket.testEntries.map { testEntry -> TestEntryResult in
                    TestEntryResult.withResult(
                        testEntry: testEntry,
                        testRunResult: TestRunResult(
                            succeeded: false,
                            exceptions: [
                                TestException(
                                    reason: "Emcee failed to execute this test: \(error)",
                                    filePathInProject: #file,
                                    lineNumber: #line
                                )
                            ],
                            duration: Date().timeIntervalSince(startedAt),
                            startTime: startedAt.timeIntervalSince1970,
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
    private func runRetrying(bucket: SchedulerBucket) throws -> TestingResult {
        let firstRun = try runBucketOnce(bucket: bucket, testsToRun: bucket.testEntries)
        
        guard bucket.testExecutionBehavior.numberOfRetries > 0 else {
            Logger.debug("numberOfRetries == 0, will not retry failed tests.")
            return firstRun
        }
        
        var lastRunResults = firstRun
        var results = [firstRun]
        for retryNumber in 0 ..< bucket.testExecutionBehavior.numberOfRetries {
            let failedTestEntriesAfterLastRun = lastRunResults.failedTests.map { $0.testEntry }
            if failedTestEntriesAfterLastRun.isEmpty {
                Logger.debug("No failed tests after last retry, so nothing to run.")
                break
            }
            Logger.debug("After last run \(failedTestEntriesAfterLastRun.count) tests have failed: \(failedTestEntriesAfterLastRun).")
            Logger.debug("Retrying them, attempt #\(retryNumber + 1) of maximum \(bucket.testExecutionBehavior.numberOfRetries) attempts")
            lastRunResults = try runBucketOnce(bucket: bucket, testsToRun: failedTestEntriesAfterLastRun)
            results.append(lastRunResults)
        }
        return try combine(runResults: results)
    }
    
    private func runBucketOnce(bucket: SchedulerBucket, testsToRun: [TestEntry]) throws -> TestingResult {
        let simulatorPool = try configuration.onDemandSimulatorPool.pool(
            key: OnDemandSimulatorPoolKey(
                developerDir: bucket.developerDir,
                testDestination: bucket.testDestination,
                testRunnerTool: bucket.testRunnerTool,
                simulatorControlTool: bucket.simulatorControlTool
            )
        )

        let allocatedSimulator = try simulatorPool.allocateSimulator(
            simulatorOperationTimeouts: bucket.simulatorOperationTimeouts
        )
        defer { allocatedSimulator.releaseSimulator() }
            
        let runner = Runner(
            configuration: RunnerConfiguration(
                buildArtifacts: bucket.buildArtifacts,
                environment: bucket.testExecutionBehavior.environment,
                pluginLocations: bucket.pluginLocations,
                simulatorSettings: bucket.simulatorSettings,
                testRunnerTool: bucket.testRunnerTool,
                testTimeoutConfiguration: bucket.testTimeoutConfiguration,
                testType: bucket.testType
            ),
            developerDirLocator: developerDirLocator,
            pluginEventBusProvider: pluginEventBusProvider,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider
        )

        let runnerResult = try runner.run(
            entries: testsToRun,
            developerDir: bucket.developerDir,
            simulator: allocatedSimulator.simulator
        )
        
        if !runnerResult.testEntryResults.filter({ $0.isLost }).isEmpty {
            Logger.warning("Some test results are lost")
            runnerResult.dumpStandardStreams()
        }
        
        return TestingResult(
            bucketId: bucket.bucketId,
            testDestination: bucket.testDestination,
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
        Logger.verboseDebug("Combining the following results from \(runResults.count) runs:")
        runResults.forEach {
            Logger.verboseDebug("Result: \($0)")
        }
        let result = try TestingResult.byMerging(testingResults: runResults)
        Logger.verboseDebug("Combined result: \(result)")
        return result
    }
}
