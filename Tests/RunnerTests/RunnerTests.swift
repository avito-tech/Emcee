import BuildArtifacts
import BuildArtifactsTestHelpers
import DateProviderTestHelpers
import DeveloperDirLocatorTestHelpers
import EventBus
import FileSystemTestHelpers
import Foundation
import EmceeLogging
import MetricsExtensions
import MetricsTestHelpers
import PluginManagerTestHelpers
import QueueModels
import Runner
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import SynchronousWaiter
import Tmp
import TestHelpers
import UniqueIdentifierGeneratorTestHelpers
import XCTest

public final class RunnerTests: XCTestCase {
    lazy var testEntry = TestEntryFixtures.testEntry()
    lazy var noOpPluginEventBusProvider = NoOoPluginEventBusProvider()
    lazy var testTimeout: TimeInterval = 3
    lazy var impactQueue = DispatchQueue(label: "impact queue")
    lazy var testRunnerProvider = FakeTestRunnerProvider()
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var fileSystem = FakeFileSystem(rootPath: tempFolder.absolutePath)
    lazy var dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100))
    lazy var runnerWasteCollector = RunnerWasteCollectorImpl()
    lazy var uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: "someId")
    
    func test___running_test_without_output_to_stream___provides_test_did_not_run_results() throws {
        testRunnerProvider.predefinedFakeTestRunner.disableTestStartedTestRunnerStreamEvents()
        testRunnerProvider.predefinedFakeTestRunner.disableTestStoppedTestRunnerStreamEvents()

        let runnerResults = try runTestEntries([testEntry])
        
        XCTAssertEqual(runnerResults.testEntryResults.count, 1)

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(testResult.testRunResults[0].exceptions.first, RunnerConstants.testDidNotRun(testEntry.testName).testException)
    }

    func test___running_test_with_successful_result___provides_successful_results() throws {
        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertTrue(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }

    func test___running_test_with_failing_result___provides_test_failed_result() throws {
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in .failure }

        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }

    func test___running_test_with_lost_result___provides_test_failed_results() throws {
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in .lost }

        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }
    
    func test___running_test___creates_plugin_event_bus() throws {
        _ = try runTestEntries([testEntry])

        XCTAssertEqual(
            noOpPluginEventBusProvider.eventBusRequests,
            1,
            "Runner should have requested event bus"
        )
    }
    
    func test___running_test___tears_down_plugin_event_bus() throws {
        let busTornDownExpectation = expectation(description: "Event Bus has been torn down")
        
        noOpPluginEventBusProvider.eventBus.add(
            stream: BlockBasedEventStream { (busEvent: BusEvent) in
                switch busEvent {
                case .runnerEvent:
                    break
                case .tearDown:
                    busTornDownExpectation.fulfill()
                }
            }
        )
        
        _ = try runTestEntries([testEntry])

        wait(for: [busTornDownExpectation], timeout: 15)
    }

    func test___running_test_without_stop_event_output_to_stream___revives_and_attempts_to_run_it_again() throws {
        testRunnerProvider.predefinedFakeTestRunner.disableTestStoppedTestRunnerStreamEvents()

        var numberOfAttemptsToRunTest = 0
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in
            numberOfAttemptsToRunTest += 1
            return .success
        }

        let runnerResults = try runTestEntries([testEntry])

        XCTAssertEqual(numberOfAttemptsToRunTest, 2)

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(testResult.testRunResults[0].exceptions.first, RunnerConstants.testDidNotRun(testEntry.testName).testException)
    }
    
    func test___running_test_without_stop_event___does_not_revive___when_revive_is_disabled() throws {
        testRunnerProvider.predefinedFakeTestRunner.disableTestStoppedTestRunnerStreamEvents()

        var numberOfAttemptsToRunTest = 0
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in
            numberOfAttemptsToRunTest += 1
            return .success
        }

        let runnerResults = try runTestEntries([testEntry], environment: [Runner.skipReviveAttemptsEnvName: "true"])

        XCTAssertEqual(numberOfAttemptsToRunTest, 1)

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(testResult.testRunResults[0].exceptions.first, RunnerConstants.testDidNotRun(testEntry.testName).testException)
    }

    func test___running_test_and_reviving_after_test_stopped_event_loss___provides_back_correct_result() throws {
        var didRevive = false
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in
            didRevive = true
            return .success
        }

        testRunnerProvider.predefinedFakeTestRunner.onTestStopped = { testStoppedEvent, testRunnerStream in
            // simulate situation when first testStoppedEvent gets lost
            if didRevive {
                let handler = FakeTestRunner.testStoppedHandlerForNormalEventStreaming()
                handler(testStoppedEvent, testRunnerStream)
            }
        }

        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertTrue(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }

    func test___if_test_runner_fails_to_run___runner_provides_back_all_tests_as_failed() throws {
        testRunnerProvider.predefinedFakeTestRunner.makeRunThrowErrors()
        
        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            return XCTFail("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(
            testResult.testRunResults[0].exceptions.first,
            RunnerConstants.failedToStartTestRunner(FakeTestRunner.SomeError()).testException
        )
    }
    
    func test___if_test_runner_fails_to_run___test_runner_stream_is_closed() throws {
        let eventExpectation = expectationForDidRunEvent()
        
        _ = try runTestEntries([testEntry])

        wait(for: [eventExpectation], timeout: 15)
    }
    
    func test___if_test_timeout___test_timeout_reason_reported() throws {
        testTimeout = 1
        testRunnerProvider.predefinedFakeTestRunner.disableTestStoppedTestRunnerStreamEvents()
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in
            SynchronousWaiter().wait(
                timeout: self.testTimeout + 3.0,
                description: "Artificial wait to imitate test timeout"
            )
            return .failure
        }
        
        impactQueue.asyncAfter(deadline: .now() + 1.0) {
            self.dateProvider.result += self.testTimeout + 1
        }
        
        let runnerResults = try runTestEntries([testEntry])
        
        guard runnerResults.testEntryResults.count == 1, let testEntryResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of results")
        }
        guard testEntryResult.testRunResults.count == 1, let testRunResult = testEntryResult.testRunResults.first else {
            failTest("Unexpected number of results")
        }
        XCTAssertFalse(testRunResult.succeeded)
        XCTAssertEqual(
            testRunResult.exceptions.first,
            RunnerConstants.testTimeout(testTimeout).testException
        )
    }
    
    func test___runner_waits_for_stream_to_close() throws {
        let streamIsStillOpenExpectation = expectationForDidRunEvent()
        streamIsStillOpenExpectation.expectationDescription = "Stream is still open (hasn't been closed)"
        streamIsStillOpenExpectation.isInverted = true
        
        let streamClosedExpectation = expectationForDidRunEvent()
        
        let handlerInvokedExpectation = XCTestExpectation(description: "stream close handler called")
        
        testRunnerProvider.predefinedFakeTestRunner.onStreamClose = { testRunnerStream in
            self.wait(for: [streamIsStillOpenExpectation], timeout: 5)
            
            testRunnerStream.closeStream()
            
            self.wait(for: [streamClosedExpectation], timeout: 5)
            
            handlerInvokedExpectation.fulfill()
        }
        
        _ = try runTestEntries([testEntry])
        
        wait(for: [handlerInvokedExpectation], timeout: 5)
    }
    
    func test___deletes_tests_working_directory___after_run() throws {
        let testsWorkingDirDeletedExpectation = XCTestExpectation(description: "testsWorkingDir is deleted")
        fileSystem.onDelete = { [tempFolder, uniqueIdentifierGenerator] path in
            if path == tempFolder.pathWith(components: [Runner.testsWorkingDir, uniqueIdentifierGenerator.generate()]) {
                testsWorkingDirDeletedExpectation.fulfill()
            }
        }
        
        _ = try runTestEntries([testEntry])
        
        wait(for: [testsWorkingDirDeletedExpectation], timeout: 0)
    }
    
    func test___when_exception_outside_test_started_test_finished_happens___these_exceptions_are_appended_to_all_lost_tests() throws {
        let outOfScopeException = TestException(reason: "some out-of-scope exception", filePathInProject: "", lineNumber: 0)
        
        testRunnerProvider.predefinedFakeTestRunner.onStreamOpen = { testRunnerStream in
            testRunnerStream.openStream()
            testRunnerStream.caughtException(testException: outOfScopeException)
        }
        testRunnerProvider.predefinedFakeTestRunner.disableTestStartedTestRunnerStreamEvents()
        testRunnerProvider.predefinedFakeTestRunner.disableTestStoppedTestRunnerStreamEvents()
        
        let testEntry1 = TestEntryFixtures.testEntry(className: "class1", methodName: "test1")
        let testEntry2 = TestEntryFixtures.testEntry(className: "class2", methodName: "test2")

        let runnerResults = try runTestEntries([testEntry1, testEntry2])

        guard runnerResults.testEntryResults.count == 2 else {
            failTest("Unexpected number of test results")
        }

        for testEntryResult in runnerResults.testEntryResults {
            guard testEntryResult.testRunResults.count == 1 else {
                failTest("Unexpected number of test run results")
            }
            
            let testRunResult = testEntryResult.testRunResults[0]
            assert {
                testRunResult.exceptions
            } equals: {
                [
                    outOfScopeException,
                    RunnerConstants.testDidNotRun(testEntryResult.testEntry.testName).testException
                ]
            }
        }
    }
    
    func test___after_test_execution___logs_are_attached_to_result___when_log_capturing_is_enabled() throws {
        testRunnerProvider.predefinedFakeTestRunner.onStreamOpen = { testRunnerStream in
            testRunnerStream.openStream()
            
            testRunnerStream.logCaptured(entry: TestLogEntry(contents: "first log"))
            testRunnerStream.logCaptured(entry: TestLogEntry(contents: "second log"))
        }

        let runnerResults = try runTestEntries([testEntry], environment: [Runner.logCapturingModeEnvName: Runner.LogCapturingMode.allLogs.rawValue])
        
        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        XCTAssertEqual(
            testResult.testRunResults[0].logs,
            [
                TestLogEntry(contents: "first log"),
                TestLogEntry(contents: "second log"),
            ]
        )
    }
    
    func test___after_test_execution___logs_are_not_attached_to_result___when_log_capturing_is_disabled() throws {
        testRunnerProvider.predefinedFakeTestRunner.onStreamOpen = { testRunnerStream in
            testRunnerStream.openStream()
            
            testRunnerStream.logCaptured(entry: TestLogEntry(contents: "first log"))
            testRunnerStream.logCaptured(entry: TestLogEntry(contents: "second log"))
        }

        let runnerResults = try runTestEntries([testEntry])
        
        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }

        assertTrue {
            testResult.testRunResults[0].logs.isEmpty
        }
    }
    
    func test___after_test_execution___crash_logs_are_attached_to_result___when_only_crash_logs_capturing_is_enabled() throws {
        let crashLogEntry = TestLogEntry(contents: "Process: Tratata, Crashed Thread: Some Index")
        
        testRunnerProvider.predefinedFakeTestRunner.onStreamOpen = { testRunnerStream in
            testRunnerStream.openStream()
            
            testRunnerStream.logCaptured(entry: TestLogEntry(contents: "first log"))
            testRunnerStream.logCaptured(entry: crashLogEntry)
        }

        let runnerResults = try runTestEntries([testEntry], environment: [Runner.logCapturingModeEnvName: Runner.LogCapturingMode.onlyCrashLogs.rawValue])
        
        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            failTest("Unexpected number of test results")
        }
        
        assert {
            testResult.testRunResults[0].logs
        } equals: {
            [crashLogEntry]
        }
    }
    
    func test___after_test_crash___logs_are_attached_to_result___when_log_capturing_is_enabled() throws {
        let logEntry = TestLogEntry(contents: "log entry contents")
        
        testRunnerProvider.predefinedFakeTestRunner.onStreamOpen = { testRunnerStream in
            testRunnerStream.openStream()
            testRunnerStream.logCaptured(entry: logEntry)
        }
        testRunnerProvider.predefinedFakeTestRunner.disableTestStartedTestRunnerStreamEvents()
        testRunnerProvider.predefinedFakeTestRunner.disableTestStoppedTestRunnerStreamEvents()
        
        let testEntry1 = TestEntryFixtures.testEntry(className: "class1", methodName: "test1")
        let testEntry2 = TestEntryFixtures.testEntry(className: "class2", methodName: "test2")

        let runnerResults = try runTestEntries([testEntry1, testEntry2], environment: [Runner.logCapturingModeEnvName: Runner.LogCapturingMode.allLogs.rawValue])

        guard runnerResults.testEntryResults.count == 2 else {
            failTest("Unexpected number of test results")
        }

        for testEntryResult in runnerResults.testEntryResults {
            guard testEntryResult.testRunResults.count == 1 else {
                failTest("Unexpected number of test run results")
            }
            
            let testRunResult = testEntryResult.testRunResults[0]
            assert {
                testRunResult.logs
            } equals: {
                [
                    logEntry
                ]
            }
        }
    }
    
    func test___additional_environment_from_runner_sends_to_test_context() throws {
        testRunnerProvider.predefinedFakeTestRunner.additionalEnvironmentReturns = ["key": "value"]
        _ = try runTestEntries([testEntry])

        XCTAssertEqual(testRunnerProvider.predefinedFakeTestRunner.testContext?.environment["key"], "value")
    }
    
    func test___test_context_contains_valid_path_for_runner_working_dir() throws {
        _ = try runTestEntries([testEntry])

        XCTAssertEqual(
            testRunnerProvider.predefinedFakeTestRunner.testContext?.testRunnerWorkingDirectory,
            tempFolder.absolutePath.appending(components: [Runner.runnerWorkingDir, uniqueIdentifierGenerator.value])
        )
    }
    
    func test___test_context_contains_valid_path_for_tests_working_dir() throws {
        _ = try runTestEntries([testEntry])

        XCTAssertEqual(
            testRunnerProvider.predefinedFakeTestRunner.testContext?.testsWorkingDirectory,
            tempFolder.absolutePath.appending(components: [Runner.testsWorkingDir, uniqueIdentifierGenerator.value])
        )
    }
    
    func test___temporary_folder_for_runner___is_collected() throws {
        _ = try runTestEntries([testEntry])
        
        assertTrue {
            runnerWasteCollector.collectedPaths.contains { path in
                path == tempFolder.pathWith(components: [Runner.runnerWorkingDir, uniqueIdentifierGenerator.value])
            }
        }
    }
    
    func test___temporary_folder_for_tests___is_collected() throws {
        _ = try runTestEntries([testEntry])
        
        assertTrue {
            runnerWasteCollector.collectedPaths.contains { path in
                path == tempFolder.absolutePath.appending(components: [Runner.testsWorkingDir, uniqueIdentifierGenerator.value])
            }
        }
    }
    
    func test___simulator_dead_cache___is_collected() throws {
        _ = try runTestEntries([testEntry])
        
        assertTrue {
            runnerWasteCollector.collectedPaths.contains { path in
                path == simulator.path.appending(relativePath: "data/Library/Caches/com.apple.containermanagerd/Dead")
            }
        }
    }
    
    private func expectationForDidRunEvent() -> XCTestExpectation {
        let eventExpectation = XCTestExpectation(description: "didRun event has been sent")
        
        noOpPluginEventBusProvider.eventBus.add(
            stream: BlockBasedEventStream { (busEvent: BusEvent) in
                switch busEvent {
                case let .runnerEvent(runnerEvent):
                    switch runnerEvent {
                    case .didRun:
                        eventExpectation.fulfill()
                    case .willRun, .testStarted, .testFinished:
                        break
                    }
                case .tearDown:
                    break
                }
            }
        )
        
        return eventExpectation
    }
    
    private func runTestEntries(
        _ testEntries: [TestEntry],
        environment: [String: String] = [:]
    ) throws -> RunnerRunResult {
        let runner = Runner(
            configuration: createRunnerConfig(environment: environment),
            dateProvider: dateProvider,
            developerDirLocator: FakeDeveloperDirLocator(result: tempFolder.absolutePath),
            fileSystem: fileSystem,
            logger: .noOp,
            persistentMetricsJobId: nil,
            pluginEventBusProvider: noOpPluginEventBusProvider,
            runnerWasteCollectorProvider: FakeRunnerWasteCollectorProvider { [runnerWasteCollector] in
                runnerWasteCollector
            },
            specificMetricRecorder: SpecificMetricRecorderWrapper(NoOpMetricRecorder()),
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            testTimeoutCheckInterval: .milliseconds(100),
            uniqueIdentifierGenerator: uniqueIdentifierGenerator,
            version: Version(value: "version"),
            waiter: SynchronousWaiter()
        )
        return try runner.run(
            entries: testEntries,
            developerDir: .current,
            simulator: simulator
        )
    }
    
    private lazy var simulator = Simulator(
        testDestination: TestDestinationFixtures.testDestination,
        udid: UDID(value: UUID().uuidString),
        path: tempFolder.absolutePath
    )

    private func createRunnerConfig(environment: [String: String]) -> RunnerConfiguration {
        return RunnerConfiguration(
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            environment: environment,
            pluginLocations: [],
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testRunnerTool: .xcodebuild,
            testTimeoutConfiguration: TestTimeoutConfiguration(
                singleTestMaximumDuration: testTimeout,
                testRunnerMaximumSilenceDuration: 0
            ),
            testType: .logicTest
        )
    }
}
