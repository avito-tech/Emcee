import AtomicModels
import CommonTestModels
import DateProvider
import DeveloperDirLocator
import DeveloperDirModels
import EventBus
import FileSystem
import Foundation
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

public final class AppleRunner: Runner {
    public typealias C = AppleRunnerConfiguration
    
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let fileSystem: FileSystem
    private let hostname: String
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
        
    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        fileSystem: FileSystem,
        hostname: String,
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
        self.hostname = hostname
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
        configuration: AppleRunnerConfiguration
    ) throws -> RunnerRunResult {
        let runnerWasteCollector = runnerWasteCollectorProvider.createRunnerWasteCollector()
        
        if entriesToRun.isEmpty {
            return RunnerRunResult(
                runnerWasteCollector: runnerWasteCollector,
                testEntryResults: [],
                xcresultData: []
            )
        }
        
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
        
        
        runnerWasteCollector.scheduleCollection(path: testContext.testsWorkingDirectory)
        runnerWasteCollector.scheduleCollection(path: testContext.testRunnerWorkingDirectory.path)
        runnerWasteCollector.scheduleCollection(path: configuration.simulator.path.appending(relativePath: "data/Library/Caches/com.apple.containermanagerd/Dead"))
        
        let runnerResultsPreparer = RunnerResultsPreparerImpl(
            dateProvider: dateProvider,
            lostTestProcessingMode: configuration.lostTestProcessingMode,
            hostname: hostname
        )
        
        let eventBus = try pluginEventBusProvider.createEventBus(
            fileSystem: fileSystem,
            pluginLocations: configuration.appleTestConfiguration.pluginLocations
        )
        defer {
            pluginTearDownQueue.addOperation {
                eventBus.tearDown()
            }
        }
        
        var logger = self.logger
        logger.debug("Will run \(entriesToRun.count) tests on simulator \(configuration.simulator)")
        
        let singleTestMaximumDuration = configuration.appleTestConfiguration.testTimeoutConfiguration.singleTestMaximumDuration
        
        let testRunnerRunningInvocationContainer = AtomicValue<TestRunnerRunningInvocation?>(nil)
        let streamClosedCallback: CallbackWaiter<()> = waiter.createCallbackWaiter()
        
        let testRunnerStream = CompositeTestRunnerStream(
            testRunnerStreams: [
                AppleEventBusReportingTestRunnerStream(
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
                            udid: configuration.simulator.udid
                        )
                    }
                ),
                TestTimeoutTrackingTestRunnerSream(
                    dateProvider: dateProvider,
                    detectedLongRunningTest: { [dateProvider] testName, testStartedAt in
                        logger.warning("Detected long running test \(testName)")
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
                    host: hostname,
                    persistentMetricsJobId: configuration.persistentMetricsJobId,
                    specificMetricRecorder: specificMetricRecorder
                ),
                TestRunnerStreamWrapper(
                    onOpenStream: {
                        logger.trace("Started executing tests")
                    },
                    onTestStarted: { testName in
                        logger.info("Test started: \(testName)")
                    },
                    onTestException: { testException in
                        collectedTestExceptions.append(testException)
                    },
                    onLog: { logEntry in
                        switch configuration.appleTestConfiguration.testExecutionBehavior.logCapturingMode {
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
                        logger.info("Test stopped: \(testStoppedEvent.testName), \(testStoppedEvent.result)")
                    },
                    onCloseStream: {
                        logger.trace("Finished executing tests")
                        streamClosedCallback.set(result: ())
                    }
                ),
                PreflightPostflightTimeoutTrackingTestRunnerStream(
                    dateProvider: dateProvider,
                    onPreflightTimeout: {
                        logger.warning("Detected preflight timeout")
                        testRunnerRunningInvocationContainer.currentValue()?.cancel()
                    },
                    onPostflightTimeout: { testName in
                        logger.warning("Detected postflight timeout, last finished test was \(testName)")
                        testRunnerRunningInvocationContainer.currentValue()?.cancel()
                    },
                    maximumPreflightDuration: configuration.appleTestConfiguration.testTimeoutConfiguration.testRunnerMaximumSilenceDuration,
                    maximumPostflightDuration: configuration.appleTestConfiguration.testTimeoutConfiguration.testRunnerMaximumSilenceDuration,
                    pollPeriod: testTimeoutCheckInterval
                )
            ]
        )
        
        let zippedResultBundleOutputPath: AbsolutePath?
        if (configuration.appleTestConfiguration.resultBundlesUrl != nil) {
            zippedResultBundleOutputPath = try tempFolder.createDirectory(components: []).appending("compressedBundle.zip")
        } else {
            zippedResultBundleOutputPath = nil
        }
        
        let runningInvocation = try testRunner.prepareTestRun(
            buildArtifacts: configuration.appleTestConfiguration.buildArtifacts,
            developerDirLocator: developerDirLocator,
            entriesToRun: entriesToRun,
            logger: logger,
            specificMetricRecorder: specificMetricRecorder,
            testContext: testContext,
            testRunnerStream: testRunnerStream,
            zippedResultBundleOutputPath: zippedResultBundleOutputPath
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

        let xcresultData: [Data]
        if let zippedResultBundleOutputPath = zippedResultBundleOutputPath {
            if FileManager().fileExists(
                atPath: zippedResultBundleOutputPath.pathString
            ), let zippedResultBundleContents = FileManager().contents(atPath: zippedResultBundleOutputPath.pathString)  {
                var components = URLComponents(
                    url: configuration.appleTestConfiguration.resultBundlesUrl!,
                    resolvingAgainstBaseURL: true
                )!
                components.queryItems = [
                    URLQueryItem(
                        name: "filename",
                        value: "\(UUID().uuidString)"
                    )
                ]
                var urlRequest = URLRequest(
                    url: components.url!
                )
                urlRequest.httpMethod = "POST"
                let sema = DispatchSemaphore(value: 0)
                URLSession(configuration: .default).uploadTask(
                    with: urlRequest,
                    from: zippedResultBundleContents,
                    completionHandler: { data, response, error in
                        logger.trace("Bundle upload \((response as? HTTPURLResponse)?.statusCode ?? 0)")
                        if let error = error {
                            logger.error("Bundle upload error: \(error)")
                        }
                        sema.signal()
                    }
                ).resume()
                sema.wait()
//                xcresultData = [zippedResultBundleContents]
            } else {
                xcresultData = []
                logger.error("Missing expected zipped result bundle at \(zippedResultBundleOutputPath.pathString)")
            }
        } else {
            xcresultData = []
        }
        
        let result = runnerResultsPreparer.prepareResults(
            collectedTestStoppedEvents: collectedTestStoppedEvents,
            collectedTestExceptions: collectedTestExceptions,
            collectedLogs: collectedLogs,
            requestedEntriesToRun: entriesToRun,
            udid: configuration.simulator.udid
        )
        
        logger.trace("Got \(result.count) of expected \(entriesToRun.count) results after running tests on \(configuration.simulator): \(result)")
        
        return RunnerRunResult(
            runnerWasteCollector: runnerWasteCollector,
            testEntryResults: result,
            xcresultData: []
        )
    }
    
    private func createTestContext(
        configuration: AppleRunnerConfiguration,
        testRunner: TestRunner
    ) throws -> AppleTestContext {
        let contextId = uniqueIdentifierGenerator.generate()
        let testsWorkingDirectory = try tempFolder.createDirectory(
            components: [RunnerConstants.testsWorkingDir, contextId]
        )
        let testRunnerWorkingDirectory = TestRunnerWorkingDirectory(
            path: try tempFolder.createDirectory(
                components: [RunnerConstants.runnerWorkingDir, contextId]
            )
        )
        
        let additionalEnvironment = testRunner.additionalEnvironment(
            testRunnerWorkingDirectory: testRunnerWorkingDirectory
        )
        var environment = configuration.appleTestConfiguration.testExecutionBehavior.environment
        environment[TestsWorkingDirectorySupport.envTestsWorkingDirectory] = testsWorkingDirectory.pathString
        environment = try developerDirLocator.suitableEnvironment(
            forDeveloperDir: configuration.appleTestConfiguration.developerDir,
            byUpdatingEnvironment: environment
        )
        additionalEnvironment.forEach {
            environment[$0.key] = $0.value
        }
        
        return AppleTestContext(
            contextId: contextId,
            developerDir: configuration.appleTestConfiguration.developerDir,
            environment: environment,
            userInsertedLibraries: configuration.appleTestConfiguration.testExecutionBehavior.userInsertedLibraries,
            simulator: configuration.simulator,
            testRunnerWorkingDirectory: testRunnerWorkingDirectory,
            testsWorkingDirectory: testsWorkingDirectory,
            testAttachmentLifetime: configuration.appleTestConfiguration.testAttachmentLifetime
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
