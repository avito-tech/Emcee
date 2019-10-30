import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import ResourceLocationResolverTestHelpers
import Runner
import SimulatorPoolTestHelpers
import TemporaryStuff
import XCTest
import fbxctest

final class FbxctestBasedTestRunnerTests: XCTestCase, TestRunnerStream {
    let runner = FbxctestBasedTestRunner(
        fbxctestLocation: FbxctestLocationFixtures.fakeFbxctestLocation,
        resourceLocationResolver: FakeResourceLocationResolver.throwing()
    )
    
    func test___when_app_is_missing_and_test_type_is_ui_test___throws() throws {
        let temporaryFolder = try TemporaryFolder()
        XCTAssertThrowsError(
            _ = try runner.run(
                buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: nil, runner: "", xcTestBundle: "", additionalApplicationBundles: []),
                developerDirLocator: FakeDeveloperDirLocator(),
                entriesToRun: [TestEntryFixtures.testEntry()],
                maximumAllowedSilenceDuration: .infinity,
                simulator: SimulatorFixture.simulator(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                singleTestMaximumDuration: .infinity,
                temporaryFolder: temporaryFolder,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: self,
                testType: .uiTest
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
                simulator: SimulatorFixture.simulator(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                singleTestMaximumDuration: .infinity,
                temporaryFolder: temporaryFolder,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: self,
                testType: .uiTest
            )
        )
    }
    
    func testStarted(testName: TestName) {}
    
    func testStopped(testStoppedEvent: TestStoppedEvent) {}
}

