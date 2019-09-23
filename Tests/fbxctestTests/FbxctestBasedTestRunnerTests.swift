import Models
import ModelsTestHelpers
import ResourceLocationResolver
import Runner
import XCTest
import fbxctest

final class FbxctestBasedTestRunnerTests: XCTestCase, TestRunnerStream {
    let runner = FbxctestBasedTestRunner(
        fbxctestLocation: FbxctestLocationFixtures.fakeFbxctestLocation,
        resourceLocationResolver: try! ResourceLocationResolver()
    )
    
    var allStartedTests = [TestName]()
    var allStoppedEvents = [TestStoppedEvent]()
    
    func test___when_app_is_missing_and_test_type_is_ui_test___error_result_provided() throws {
        _ = runner.run(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: nil, runner: "", xcTestBundle: "", additionalApplicationBundles: []),
            entriesToRun: [TestEntryFixtures.testEntry()],
            maximumAllowedSilenceDuration: .infinity,
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            singleTestMaximumDuration: .infinity,
            testContext: TestContextFixtures().testContext,
            testRunnerStream: self,
            testType: .uiTest
        )
        
        XCTAssertEqual(allStartedTests, [TestEntryFixtures.testEntry().testName])
        
        guard allStoppedEvents.count == 1, let stoppedEvent = allStoppedEvents.last else {
            return XCTFail("Unexpected stopped event count")
        }
        XCTAssertEqual(stoppedEvent.result, .lost)
        XCTAssertEqual(stoppedEvent.testDuration, 0.0)
        XCTAssertEqual(
            stoppedEvent.testExceptions.map { $0.reason },
            ["Failed to execute fbxctest: \(RunnerError.noAppBundleDefinedForUiOrApplicationTesting)"]
        )
    }
    
    func test___when_runner_app_is_missing_and_test_type_is_ui_test___error_result_provided() throws {
        _ = runner.run(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: "", runner: nil, xcTestBundle: "", additionalApplicationBundles: []),
            entriesToRun: [TestEntryFixtures.testEntry()],
            maximumAllowedSilenceDuration: .infinity,
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            singleTestMaximumDuration: .infinity,
            testContext: TestContextFixtures().testContext,
            testRunnerStream: self,
            testType: .uiTest
        )
        
        XCTAssertEqual(allStartedTests, [TestEntryFixtures.testEntry().testName])
        
        guard allStoppedEvents.count == 1, let stoppedEvent = allStoppedEvents.last else {
            return XCTFail("Unexpected stopped event count")
        }
        XCTAssertEqual(stoppedEvent.result, .lost)
        XCTAssertEqual(stoppedEvent.testDuration, 0.0)
        XCTAssertEqual(
            stoppedEvent.testExceptions.map { $0.reason },
            ["Failed to execute fbxctest: \(RunnerError.noRunnerAppDefinedForUiTesting)"]
        )
    }
    
    func testStarted(testName: TestName) {
        allStartedTests.append(testName)
    }
    
    func testStopped(testStoppedEvent: TestStoppedEvent) {
        allStoppedEvents.append(testStoppedEvent)
    }
}

