import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import Runner
import TemporaryStuff
import XCTest
import fbxctest

final class FbxctestBasedTestRunnerTests: XCTestCase, TestRunnerStream {
    let runner = FbxctestBasedTestRunner(
        fbxctestLocation: FbxctestLocationFixtures.fakeFbxctestLocation,
        resourceLocationResolver: try! ResourceLocationResolver()
    )
    
    func test___when_app_is_missing_and_test_type_is_ui_test___throws() throws {
        let temporaryFolder = try TemporaryFolder()
        XCTAssertThrowsError(
            _ = try runner.run(
                buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: nil, runner: "", xcTestBundle: "", additionalApplicationBundles: []),
                developerDirLocator: FakeDeveloperDirLocator(),
                entriesToRun: [TestEntryFixtures.testEntry()],
                maximumAllowedSilenceDuration: .infinity,
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                singleTestMaximumDuration: .infinity,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: self,
                testType: .uiTest,
                temporaryFolder: temporaryFolder
            )
        )
    }
    
    func test___when_runner_app_is_missing_and_test_type_is_ui_test___throws() throws {
        let temporaryFolder = try TemporaryFolder()
        XCTAssertThrowsError(
            _ = try runner.run(
                buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: "", runner: nil, xcTestBundle: "", additionalApplicationBundles: []),
                developerDirLocator: FakeDeveloperDirLocator(),
                entriesToRun: [TestEntryFixtures.testEntry()],
                maximumAllowedSilenceDuration: .infinity,
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                singleTestMaximumDuration: .infinity,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: self,
                testType: .uiTest,
                temporaryFolder: temporaryFolder
            )
        )
    }
    
    func testStarted(testName: TestName) {}
    
    func testStopped(testStoppedEvent: TestStoppedEvent) {}
}

