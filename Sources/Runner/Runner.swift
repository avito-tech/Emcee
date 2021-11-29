import AtomicModels
import DateProvider
import DeveloperDirLocator
import DeveloperDirModels
import EventBus
import FileSystem
import Foundation
import LocalHostDeterminer
import EmceeLogging
import Metrics
import MetricsExtensions
import PathLib
import PluginManager
import ProcessController
import QueueModels
import RunnerModels
import SimulatorPoolModels
import SynchronousWaiter
import TestsWorkingDirectorySupport
import Tmp
import UniqueIdentifierGenerator

public final class Runner {
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let logger: ContextualLogger
    private let pluginEventBusProvider: PluginEventBusProvider
    private let pluginTearDownQueue = OperationQueue()
    private let runnerWasteCollectorProvider: RunnerWasteCollectorProvider
    private let specificMetricRecorder: SpecificMetricRecorder
    private let tempFolder: TemporaryFolder
    private let testRunnerProvider: TestRunnerProvider
    private let testTimeoutCheckInterval: DispatchTimeInterval
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator
    private let version: Version
    private let waiter: Waiter
    
    public static let logCapturingModeEnvName = "EMCEE_LOG_CAPTURE_MODE"
    
    public static let runnerWorkingDir = "runnerWorkingDir"
    public static let testsWorkingDir = "testsWorkingDir"
    
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        logger: ContextualLogger,
        pluginEventBusProvider: PluginEventBusProvider,
        runnerWasteCollectorProvider: RunnerWasteCollectorProvider,
        specificMetricRecorder: SpecificMetricRecorder,
        tempFolder: TemporaryFolder,
        testRunnerProvider: TestRunnerProvider,
        testTimeoutCheckInterval: DispatchTimeInterval = .seconds(1),
        uniqueIdentifierGenerator: UniqueIdentifierGenerator,
        version: Version,
        waiter: Waiter
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.fileSystem = fileSystem
        self.logger = logger
        self.pluginEventBusProvider = pluginEventBusProvider
        self.runnerWasteCollectorProvider = runnerWasteCollectorProvider
        self.specificMetricRecorder = specificMetricRecorder
        self.tempFolder = tempFolder
        self.testRunnerProvider = testRunnerProvider
        self.testTimeoutCheckInterval = testTimeoutCheckInterval
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
        self.version = version
        self.waiter = waiter
    }
    
    /// Runs the given tests once without any attempts to restart the failed or crashed tests.
    public func runOnce(
        entriesToRun: [TestEntry],
        configuration: RunnerConfiguration
    ) throws -> RunnerRunResult {
        if entriesToRun.isEmpty {
            return RunnerRunResult(
                entriesToRun: entriesToRun,
                testEntryResults: []
            )
        }
        
        let logCapturingMode = LogCapturingMode(rawValue: configuration.environment[Self.logCapturingModeEnvName] ?? LogCapturingMode.noLogs.rawValue) ?? .noLogs

        var collectedTestStoppedEvents = [TestStoppedEvent]()
        var collectedTestExceptions = [TestException]()
        var collectedLogs = [TestLogEntry]()
        
        let testRunner = FailureReportingTestRunnerProxy(
            dateProvider: dateProvider,
            testRunner: try testRunnerProvider.testRunner()
        )
        
        let testContext = try createTestContext(
            configuration: configuration,
            testRunner: testRunner
        )
        
        let runnerWasteCollector = runnerWasteCollectorProvider.createRunnerWasteCollector()
        runnerWasteCollector.scheduleCollection(path: testContext.testsWorkingDirectory)
        runnerWasteCollector.scheduleCollection(path: testContext.testRunnerWorkingDirectory)
        runnerWasteCollector.scheduleCollection(path: configuration.simulator.path.appending(relativePath: "data/Library/Caches/com.apple.containermanagerd/Dead"))
        
        let runnerResultsPreparer = RunnerResultsPreparerImpl(
            dateProvider: dateProvider,
            lostTestProcessingMode: configuration.lostTestProcessingMode
        )
        
        let eventBus = try pluginEventBusProvider.createEventBus(
            fileSystem: fileSystem,
            pluginLocations: configuration.pluginLocations
        )
        defer {
            pluginTearDownQueue.addOperation { [fileSystem] in
                eventBus.tearDown()
                RunnerWasteCleanerImpl(fileSystem: fileSystem).cleanWaste(runnerWasteCollector: runnerWasteCollector)
            }
        }
        
        var logger = self.logger
        logger.debug("Will run \(entriesToRun.count) tests on simulator \(configuration.simulator)")
        
        let singleTestMaximumDuration = configuration.testTimeoutConfiguration.singleTestMaximumDuration
        
        let testRunnerRunningInvocationContainer = AtomicValue<TestRunnerRunningInvocation?>(nil)
        let streamClosedCallback: CallbackWaiter<()> = waiter.createCallbackWaiter()
        
        let testRunnerStream = CompositeTestRunnerStream(
            testRunnerStreams: [
                EventBusReportingTestRunnerStream(
                    entriesToRun: entriesToRun,
                    eventBus: eventBus,
                    logger: { logger },
                    testContext: testContext,
                    resultsProvider: {
                        runnerResultsPreparer.prepareResults(
                            collectedTestStoppedEvents: collectedTestStoppedEvents,
                            collectedTestExceptions: collectedTestExceptions,
                            collectedLogs: collectedLogs,
                            requestedEntriesToRun: entriesToRun,
                            simulatorId: configuration.simulator.udid
                        )
                    }
                ),
                TestTimeoutTrackingTestRunnerSream(
                    dateProvider: dateProvider,
                    detectedLongRunningTest: { [dateProvider] testName, testStartedAt in
                        logger.debug("Detected long running test \(testName)")
                        collectedTestStoppedEvents.append(
                            TestStoppedEvent(
                                testName: testName,
                                result: .failure,
                                testDuration: dateProvider.currentDate().timeIntervalSince(testStartedAt.date),
                                testExceptions: [
                                    RunnerConstants.testTimeout(testName, singleTestMaximumDuration).testException,
                                ],
                                logs: collectedLogs,
                                testStartTimestamp: testStartedAt
                            )
                        )
                        
                        testRunnerRunningInvocationContainer.currentValue()?.cancel()
                    },
                    logger: { logger },
                    maximumTestDuration: singleTestMaximumDuration,
                    pollPeriod: testTimeoutCheckInterval
                ),
                MetricReportingTestRunnerStream(
                    dateProvider: dateProvider,
                    version: version,
                    host: LocalHostDeterminer.currentHostAddress,
                    persistentMetricsJobId: configuration.persistentMetricsJobId,
                    specificMetricRecorder: specificMetricRecorder
                ),
                TestRunnerStreamWrapper(
                    onOpenStream: {
                        logger.debug("Started executing tests")
                    },
                    onTestStarted: { testName in
                        logger.debug("Test started: \(testName)")
                    },
                    onTestException: { testException in
                        collectedTestExceptions.append(testException)
                    },
                    onLog: { logEntry in
                        switch logCapturingMode {
                        case .noLogs:
                            break
                        case .allLogs:
                            collectedLogs.append(logEntry)
                        case .onlyCrashLogs:
                            if logEntry.contents.contains("Process:") && logEntry.contents.contains("Crashed Thread:") {
                                collectedLogs.append(logEntry)
                            }
                        }
                        
                    },
                    onTestStopped: { testStoppedEvent in
                        let testStoppedEvent = testStoppedEvent.byMerging(testExceptions: collectedTestExceptions, logs: collectedLogs)
                        collectedTestStoppedEvents.append(testStoppedEvent)
                        collectedTestExceptions = []
                        collectedLogs = []
                        logger.debug("Test stopped: \(testStoppedEvent.testName), \(testStoppedEvent.result)")
                    },
                    onCloseStream: {
                        logger.debug("Finished executing tests")
                        streamClosedCallback.set(result: ())
                    }
                ),
                PreflightPostflightTimeoutTrackingTestRunnerStream(
                    dateProvider: dateProvider,
                    onPreflightTimeout: {
                        logger.debug("Detected preflight timeout")
                        testRunnerRunningInvocationContainer.currentValue()?.cancel()
                    },
                    onPostflightTimeout: { testName in
                        logger.debug("Detected postflight timeout, last finished test was \(testName)")
                        testRunnerRunningInvocationContainer.currentValue()?.cancel()
                    },
                    maximumPreflightDuration: configuration.testTimeoutConfiguration.testRunnerMaximumSilenceDuration,
                    maximumPostflightDuration: configuration.testTimeoutConfiguration.testRunnerMaximumSilenceDuration,
                    pollPeriod: testTimeoutCheckInterval
                )
            ]
        )
        
        let runningInvocation = try testRunner.prepareTestRun(
            buildArtifacts: configuration.buildArtifacts,
            developerDirLocator: developerDirLocator,
            entriesToRun: entriesToRun,
            logger: logger,
            runnerWasteCollector: runnerWasteCollector,
            simulator: configuration.simulator,
            testContext: testContext,
            testRunnerStream: testRunnerStream
        ).startExecutingTests()
        
        logger = logger
            .withMetadata(key: .subprocessId, value: "\(runningInvocation.pidInfo.pid)")
            .withMetadata(key: .subprocessName, value: "\(runningInvocation.pidInfo.name)")
        testRunnerRunningInvocationContainer.set(runningInvocation)
        defer {
            // since we refer this in closures, we must clean up to ensure no retain cycles will occur
            testRunnerRunningInvocationContainer.set(nil)
        }
        try streamClosedCallback.wait(timeout: .infinity, description: "Test Runner Stream Close")
        
        let result = runnerResultsPreparer.prepareResults(
            collectedTestStoppedEvents: collectedTestStoppedEvents,
            collectedTestExceptions: collectedTestExceptions,
            collectedLogs: collectedLogs,
            requestedEntriesToRun: entriesToRun,
            simulatorId: configuration.simulator.udid
        )
        
        logger.debug("Attempted to run \(entriesToRun.count) tests on simulator \(configuration.simulator): \(entriesToRun)")
        logger.debug("Did get \(result.count) results: \(result)")
        
        return RunnerRunResult(
            entriesToRun: entriesToRun,
            testEntryResults: result
        )
    }
    
    public enum LogCapturingMode: String, Equatable {
        case allLogs
        case onlyCrashLogs
        case noLogs
    }
    
    private func createTestContext(
        configuration: RunnerConfiguration,
        testRunner: TestRunner
    ) throws -> TestContext {
        let contextId = uniqueIdentifierGenerator.generate()
        let testsWorkingDirectory = try tempFolder.pathByCreatingDirectories(
            components: [Self.testsWorkingDir, contextId]
        )
        let testRunnerWorkingDirectory = try tempFolder.pathByCreatingDirectories(
            components: [Self.runnerWorkingDir, contextId]
        )
        
        let additionalEnvironment = testRunner.additionalEnvironment(testRunnerWorkingDirectory: testRunnerWorkingDirectory)
        var environment = configuration.environment
        environment[TestsWorkingDirectorySupport.envTestsWorkingDirectory] = testsWorkingDirectory.pathString
        environment = try developerDirLocator.suitableEnvironment(
            forDeveloperDir: configuration.developerDir,
            byUpdatingEnvironment: environment
        )
        additionalEnvironment.forEach {
            environment[$0.key] = $0.value
        }
        
        return TestContext(
            contextId: contextId,
            developerDir: configuration.developerDir,
            environment: environment,
            simulatorPath: configuration.simulator.path,
            simulatorUdid: configuration.simulator.udid,
            testDestination: configuration.simulator.testDestination,
            testRunnerWorkingDirectory: testRunnerWorkingDirectory,
            testsWorkingDirectory: testsWorkingDirectory
        )
    }
    
    private func missingEntriesForScheduledEntries(
        expectedEntriesToRun: [TestEntry],
        collectedResults: RunResult)
        -> [TestEntry]
    {
        let receivedTestEntries = Set(collectedResults.nonLostTestEntryResults.map { $0.testEntry })
        return expectedEntriesToRun.filter { !receivedTestEntries.contains($0) }
    }
}
