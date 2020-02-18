import BuildArtifacts
import BuildArtifactsTestHelpers
import DeveloperDirLocatorTestHelpers
import EventBus
import Extensions
import Foundation
import Models
import ModelsTestHelpers
import PluginManagerTestHelpers
import ResourceLocationResolverTestHelpers
import Runner
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TemporaryStuff
import XCTest

public final class RunnerTests: XCTestCase {
    let testEntry = TestEntryFixtures.testEntry()
    let noOpPluginEventBusProvider = NoOoPluginEventBusProvider()
    let resolver = FakeResourceLocationResolver.resolvingToTempFolder()
    let testRunnerProvider = FakeTestRunnerProvider()
    var tempFolder = try! TemporaryFolder()
    
    func test___running_test_without_output_to_stream___provides_test_did_not_run_results() throws {
        testRunnerProvider.predefinedFakeTestRunner.disableTestStartedTestRunnerStreamEvents()
        testRunnerProvider.predefinedFakeTestRunner.disableTestStoppedTestRunnerStreamEvents()

        let runnerResults = try runTestEntries([testEntry])
        
        XCTAssertEqual(runnerResults.testEntryResults.count, 1)

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            return XCTFail("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(testResult.testRunResults[0].exceptions[0].reason, RunnerConstants.testDidNotRun.rawValue)
    }

    func test___running_test_with_successful_result___provides_successful_results() throws {
        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            return XCTFail("Unexpected number of test results")
        }

        XCTAssertTrue(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }

    func test___running_test_with_failing_result___provides_test_failed_result() throws {
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in .failure }

        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            return XCTFail("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
    }

    func test___running_test_with_lost_result___provides_successful_results() throws {
        testRunnerProvider.predefinedFakeTestRunner.onExecuteTest = { _ in .lost }

        let runnerResults = try runTestEntries([testEntry])

        guard runnerResults.testEntryResults.count == 1, let testResult = runnerResults.testEntryResults.first else {
            return XCTFail("Unexpected number of test results")
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
            return XCTFail("Unexpected number of test results")
        }

        XCTAssertFalse(testResult.succeeded)
        XCTAssertEqual(testResult.testEntry, testEntry)
        XCTAssertEqual(testResult.testRunResults[0].exceptions[0].reason, RunnerConstants.testDidNotRun.rawValue)
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
            return XCTFail("Unexpected number of test results")
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
            testResult.testRunResults[0].exceptions[0].reason,
            RunnerConstants.failedToStartTestRunner.rawValue + ": \(FakeTestRunner.SomeError())"
        )
    }
    
    private func runTestEntries(_ testEntries: [TestEntry]) throws -> RunnerRunResult {
        let runner = Runner(
            configuration: createRunnerConfig(),
            developerDirLocator: FakeDeveloperDirLocator(result: tempFolder.absolutePath),
            pluginEventBusProvider: noOpPluginEventBusProvider,
            resourceLocationResolver: resolver,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider
        )
        return try runner.run(
            entries: testEntries,
            developerDir: .current,
            simulator: Simulator(
                testDestination: TestDestinationFixtures.testDestination,
                udid: UDID(value: UUID().uuidString),
                path: tempFolder.absolutePath
            )
        )
    }

    private func createRunnerConfig() -> RunnerConfiguration {
        return RunnerConfiguration(
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(),
            environment: [:],
            pluginLocations: [],
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
            testTimeoutConfiguration: TestTimeoutConfiguration(
                singleTestMaximumDuration: 5,
                testRunnerMaximumSilenceDuration: 0
            ),
            testType: .logicTest
        )
    }
}
