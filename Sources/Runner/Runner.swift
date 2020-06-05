import AtomicModels
import DateProvider
import DeveloperDirLocator
import EventBus
import FileSystem
import Foundation
import LocalHostDeterminer
import Logging
import Metrics
import Models
import PathLib
import PluginManager
import ProcessController
import ResourceLocationResolver
import RunnerModels
import SimulatorPoolModels
import TemporaryStuff
import TestsWorkingDirectorySupport

public final class Runner {
    private let configuration: RunnerConfiguration
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let pluginEventBusProvider: PluginEventBusProvider
    private let pluginTearDownQueue = OperationQueue()
    private let resourceLocationResolver: ResourceLocationResolver
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    
    public init(
        configuration: RunnerConfiguration,
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        pluginEventBusProvider: PluginEventBusProvider,
        resourceLocationResolver: ResourceLocationResolver,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider
    ) {
        self.configuration = configuration
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.pluginEventBusProvider = pluginEventBusProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
    }
    
    /** Runs the given tests, attempting to restart the runner in case of crash. */
    public func run(
        entries: [TestEntry],
        developerDir: DeveloperDir,
        simulator: Simulator
    ) throws -> RunnerRunResult {
        if entries.isEmpty {
            return RunnerRunResult(
                entriesToRun: entries,
                testEntryResults: [],
                subprocessStandardStreamsCaptureConfig: nil
            )
        }
        
        let runResult = RunResult()
        
        // To not retry forever.
        // It is unlikely that multiple revives would provide any results, so we leave only a single retry.
        let numberOfAttemptsToRevive = 1
        
        // Something may crash (fbxctest/xctest), many tests may be not started. Some external code that uses Runner
        // may have its own logic for restarting particular tests, but here at Runner we deal with crashes of bunches
        // of tests, many of which can be even not started. Simplifying this: if something that runs tests is crashed,
        // we should retry running tests more than if some test fails. External code will treat failed tests as it
        // is promblem in them, not in infrastructure.
        
        var reviveAttempt = 0
        var lastSubprocessStandardStreamsCaptureConfig: StandardStreamsCaptureConfig? = nil
        while runResult.nonLostTestEntryResults.count < entries.count, reviveAttempt <= numberOfAttemptsToRevive {
            let entriesToRun = missingEntriesForScheduledEntries(
                expectedEntriesToRun: entries,
                collectedResults: runResult
            )
            let runResults = try runOnce(
                entriesToRun: entriesToRun,
                developerDir: developerDir,
                simulator: simulator
            )
            lastSubprocessStandardStreamsCaptureConfig = runResults.subprocessStandardStreamsCaptureConfig
            
            runResult.append(testEntryResults: runResults.testEntryResults)
            
            if runResults.testEntryResults.filter({ !$0.isLost }).isEmpty {
                // Here, if we do not receive events at all, we will get 0 results. We try to revive a limited number of times.
                reviveAttempt += 1
                Logger.warning("Got no results. Attempting to revive #\(reviveAttempt) out of allowed \(numberOfAttemptsToRevive) attempts to revive")
            } else {
                // Here, we actually got events, so we could reset revive attempts.
                reviveAttempt = 0
            }
        }
        
        return RunnerRunResult(
            entriesToRun: entries,
            testEntryResults: testEntryResults(
                runResult: runResult,
                simulatorId: simulator.udid
            ),
            subprocessStandardStreamsCaptureConfig: lastSubprocessStandardStreamsCaptureConfig
        )
    }
    
    /// Runs the given tests once without any attempts to restart the failed or crashed tests.
    public func runOnce(
        entriesToRun: [TestEntry],
        developerDir: DeveloperDir,
        simulator: Simulator
    ) throws -> RunnerRunResult {
        if entriesToRun.isEmpty {
            Logger.info("Nothing to run!")
            return RunnerRunResult(
                entriesToRun: entriesToRun,
                testEntryResults: [],
                subprocessStandardStreamsCaptureConfig: nil
            )
        }

        var collectedTestStoppedEvents = [TestStoppedEvent]()
        var collectedTestExceptions = [TestException]()
        
        let testContext = try createTestContext(
            developerDir: developerDir,
            simulator: simulator
        )
        
        let eventBus = try pluginEventBusProvider.createEventBus(
            pluginLocations: configuration.pluginLocations
        )
        defer {
            pluginTearDownQueue.addOperation(eventBus.tearDown)
        }
        
        Logger.debug("Will run \(entriesToRun.count) tests on simulator \(simulator)")
        eventBus.post(event: .runnerEvent(.willRun(testEntries: entriesToRun, testContext: testContext)))
        
        let singleTestMaximumDuration = configuration.testTimeoutConfiguration.singleTestMaximumDuration
        
        let testRunner = try testRunnerProvider.testRunner(
            testRunnerTool: configuration.testRunnerTool
        )
        
        let testRunnerRunningInvocationContainer = AtomicValue<TestRunnerRunningInvocation?>(nil)
        
        let testRunnerStream = CompositeTestRunnerStream(
            testRunnerStreams: [
                EventBusReportingTestRunnerStream(
                    entriesToRun: entriesToRun,
                    eventBus: eventBus,
                    testContext: testContext
                ),
                TestTimeoutTrackingTestRunnerSream(
                    dateProvider: dateProvider,
                    detectedLongRunningTest: { [dateProvider] testName, testStartedAt in
                        Logger.debug("Detected long running test \(testName)")
                        collectedTestStoppedEvents.append(
                            TestStoppedEvent(
                                testName: testName,
                                result: .failure,
                                testDuration: dateProvider.currentDate().timeIntervalSince(testStartedAt),
                                testExceptions: [
                                    TestException(
                                        reason: "Test timeout. Test did not finish in time \(LoggableDuration(singleTestMaximumDuration))",
                                        filePathInProject: #file,
                                        lineNumber: #line
                                    )
                                ],
                                testStartTimestamp: testStartedAt.timeIntervalSince1970
                            )
                        )
                        
                        testRunnerRunningInvocationContainer.currentValue()?.cancel()
                    },
                    maximumTestDuration: singleTestMaximumDuration
                ),
                MetricReportingTestRunnerStream(
                    dateProvider: dateProvider
                ),
                TestRunnerStreamWrapper(
                    onTestStarted: { testName in
                        collectedTestExceptions = []
                    },
                    onTestException: { testException in
                        collectedTestExceptions.append(testException)
                    },
                    onTestStopped: { testStoppedEvent in
                        let testStoppedEvent = testStoppedEvent.byMergingTestExceptions(testExceptions: collectedTestExceptions)
                        collectedTestStoppedEvents.append(testStoppedEvent)
                        collectedTestExceptions = []
                    }
                ),
            ]
        )
        
        let testRunnerInvocation = runTestsViaTestRunner(
            testRunner: testRunner,
            entriesToRun: entriesToRun,
            simulator: simulator,
            testContext: testContext,
            testRunnerStream: testRunnerStream
        )
        let runningInvocation = testRunnerInvocation.startExecutingTests()
        testRunnerRunningInvocationContainer.set(runningInvocation)
        
        let runnerSilenceTracker = ProcessOutputSilenceTracker(
            dateProvider: dateProvider,
            fileSystem: fileSystem,
            onSilence: { [configuration] in
                Logger.debug("Test runner has been silent for too long (\(LoggableDuration(configuration.testTimeoutConfiguration.testRunnerMaximumSilenceDuration))), terminating tests")
                runningInvocation.cancel()
            },
            silenceDuration: configuration.testTimeoutConfiguration.testRunnerMaximumSilenceDuration,
            standardStreamsCaptureConfig: runningInvocation.output,
            subprocessInfo: runningInvocation.subprocessInfo
        )
        runnerSilenceTracker.whileTracking {
            runningInvocation.wait()
        }
        
        let result = prepareResults(
            collectedTestStoppedEvents: collectedTestStoppedEvents,
            requestedEntriesToRun: entriesToRun,
            simulatorId: simulator.udid
        )
        
        eventBus.post(event: .runnerEvent(.didRun(results: result, testContext: testContext)))
        
        Logger.debug("Attempted to run \(entriesToRun.count) tests on simulator \(simulator): \(entriesToRun)")
        Logger.debug("Did get \(result.count) results: \(result)")
        
        return RunnerRunResult(
            entriesToRun: entriesToRun,
            testEntryResults: result,
            subprocessStandardStreamsCaptureConfig: runningInvocation.output
        )
    }
    
    private func createTestContext(
        developerDir: DeveloperDir,
        simulator: Simulator
    ) throws -> TestContext {
        let testsWorkingDirectory = try tempFolder.pathByCreatingDirectories(
            components: ["testsWorkingDir", UUID().uuidString]
        )

        var environment = configuration.environment
        environment[TestsWorkingDirectorySupport.envTestsWorkingDirectory] = testsWorkingDirectory.pathString
        environment = try developerDirLocator.suitableEnvironment(forDeveloperDir: developerDir, byUpdatingEnvironment: environment)

        return TestContext(
            developerDir: developerDir,
            environment: environment,
            simulatorPath: simulator.path.fileUrl,
            simulatorUdid: simulator.udid,
            testDestination: simulator.testDestination
        )
    }
    
    private func runTestsViaTestRunner(
        testRunner: TestRunner,
        entriesToRun: [TestEntry],
        simulator: Simulator,
        testContext: TestContext,
        testRunnerStream: TestRunnerStream
    ) -> TestRunnerInvocation {
        cleanUpDeadCache(simulator: simulator)
        do {
            return try testRunner.prepareTestRun(
                buildArtifacts: configuration.buildArtifacts,
                developerDirLocator: developerDirLocator,
                entriesToRun: entriesToRun,
                simulator: simulator,
                temporaryFolder: tempFolder,
                testContext: testContext,
                testRunnerStream: testRunnerStream,
                testType: configuration.testType
            )
        } catch {
            return generateTestFailuresBecauseOfRunnerFailure(
                runnerError: error,
                entriesToRun: entriesToRun,
                testRunnerStream: testRunnerStream
            )
        }
    }
    
    private func cleanUpDeadCache(simulator: Simulator) {
        let deadCachePath = simulator.path.appending(relativePath: RelativePath("data/Library/Caches/com.apple.containermanagerd/Dead"))
        do {
            if FileManager.default.fileExists(atPath: deadCachePath.pathString) {
                Logger.debug("Will attempt to clean up simulator dead cache at: \(deadCachePath)")
                try FileManager.default.removeItem(at: deadCachePath.fileUrl)
            }
        } catch {
            Logger.warning("Failed to delete dead cache at \(deadCachePath): \(error)")
        }
    }
    
    private func generateTestFailuresBecauseOfRunnerFailure(
        runnerError: Error,
        entriesToRun: [TestEntry],
        testRunnerStream: TestRunnerStream
    ) -> TestRunnerInvocation {
        for testEntry in entriesToRun {
            testRunnerStream.testStarted(testName: testEntry.testName)
            testRunnerStream.testStopped(
                testStoppedEvent: TestStoppedEvent(
                    testName: testEntry.testName,
                    result: .lost,
                    testDuration: 0,
                    testExceptions: [
                        TestException(reason: RunnerConstants.failedToStartTestRunner.rawValue + ": \(runnerError)", filePathInProject: #file, lineNumber: #line)
                    ],
                    testStartTimestamp: Date().timeIntervalSince1970
                )
            )
        }
        return NoOpTestRunnerInvocation()
    }
    
    private func prepareResults(
        collectedTestStoppedEvents: [TestStoppedEvent],
        requestedEntriesToRun: [TestEntry],
        simulatorId: UDID
    ) -> [TestEntryResult] {
        return requestedEntriesToRun.map { requestedEntryToRun in
            prepareResult(
                requestedEntryToRun: requestedEntryToRun,
                simulatorId: simulatorId,
                collectedTestStoppedEvents: collectedTestStoppedEvents
            )
        }
    }
    
    private func prepareResult(
        requestedEntryToRun: TestEntry,
        simulatorId: UDID,
        collectedTestStoppedEvents: [TestStoppedEvent]
    ) -> TestEntryResult {
        let correspondingTestStoppedEvents = testStoppedEvents(
            testName: requestedEntryToRun.testName,
            collectedTestStoppedEvents: collectedTestStoppedEvents
        )
        return testEntryResultForFinishedTest(
            simulatorId: simulatorId,
            testEntry: requestedEntryToRun,
            testStoppedEvents: correspondingTestStoppedEvents
        )
    }
    
    private func testEntryResultForFinishedTest(
        simulatorId: UDID,
        testEntry: TestEntry,
        testStoppedEvents: [TestStoppedEvent]
    ) -> TestEntryResult {
        guard !testStoppedEvents.isEmpty else {
            return .lost(testEntry: testEntry)
        }
        return TestEntryResult.withResults(
            testEntry: testEntry,
            testRunResults: testStoppedEvents.map { testStoppedEvent -> TestRunResult in
                TestRunResult(
                    succeeded: testStoppedEvent.succeeded,
                    exceptions: testStoppedEvent.testExceptions,
                    duration: testStoppedEvent.testDuration,
                    startTime: testStoppedEvent.testStartTimestamp,
                    hostName: LocalHostDeterminer.currentHostAddress,
                    simulatorId: simulatorId
                )
            }
        )
    }
    
    private func testStoppedEvents(
        testName: TestName,
        collectedTestStoppedEvents: [TestStoppedEvent]
    ) -> [TestStoppedEvent] {
        return collectedTestStoppedEvents.filter { $0.testName == testName }
    }
    
    private func missingEntriesForScheduledEntries(
        expectedEntriesToRun: [TestEntry],
        collectedResults: RunResult)
        -> [TestEntry]
    {
        let receivedTestEntries = Set(collectedResults.nonLostTestEntryResults.map { $0.testEntry })
        return expectedEntriesToRun.filter { !receivedTestEntries.contains($0) }
    }
    
    private func testEntryResults(
        runResult: RunResult,
        simulatorId: UDID
    ) -> [TestEntryResult] {
        return runResult.testEntryResults.map {
            if $0.isLost {
                return resultForSingleTestThatDidNotRun(
                    simulatorId: simulatorId,
                    testEntry: $0.testEntry
                )
            } else {
                return $0
            }
        }
    }
    
    private func resultForSingleTestThatDidNotRun(
        simulatorId: UDID,
        testEntry: TestEntry
    ) -> TestEntryResult {
        return .withResult(
            testEntry: testEntry,
            testRunResult: TestRunResult(
                succeeded: false,
                exceptions: [
                    TestException(
                        reason: RunnerConstants.testDidNotRun.rawValue,
                        filePathInProject: #file,
                        lineNumber: #line
                    )
                ],
                duration: 0,
                startTime: Date().timeIntervalSince1970,
                hostName: LocalHostDeterminer.currentHostAddress,
                simulatorId: simulatorId
            )
        )
    }
}

private extension TestStoppedEvent {
    func byMergingTestExceptions(
        testExceptions: [TestException]
    ) -> TestStoppedEvent {
        return TestStoppedEvent(
            testName: testName,
            result: result,
            testDuration: testDuration,
            testExceptions: testExceptions + self.testExceptions,
            testStartTimestamp: testStartTimestamp
        )
    }
}

private class NoOpTestRunnerInvocation: TestRunnerInvocation {
    private class NoOpTestRunnerRunningInvocation: TestRunnerRunningInvocation {
        init() {}
        let output = StandardStreamsCaptureConfig()
        let subprocessInfo = SubprocessInfo(subprocessId: 0, subprocessName: "no-op process")
        func cancel() {}
        func wait() {}
    }
    
    init() {}
    
    func startExecutingTests() -> TestRunnerRunningInvocation { NoOpTestRunnerRunningInvocation() }
}
