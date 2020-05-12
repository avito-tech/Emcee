import BuildArtifactsTestHelpers
import DeveloperDirLocatorTestHelpers
import Models
import ModelsTestHelpers
import ProcessControllerTestHelpers
import ResourceLocationResolverTestHelpers
import Runner
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import TemporaryStuff
import XCTest
import fbxctest

final class FbxctestBasedTestRunnerTests: XCTestCase, TestRunnerStream {
    let runner = FbxctestBasedTestRunner(
        fbxctestLocation: FbxctestLocationFixtures.fakeFbxctestLocation,
        processControllerProvider: FakeProcessControllerProvider(),
        resourceLocationResolver: FakeResourceLocationResolver.throwing()
    )
    let testTimeoutConfiguration = TestTimeoutConfiguration(
        singleTestMaximumDuration: .infinity,
        testRunnerMaximumSilenceDuration: .infinity
    )
    
    func test___when_app_is_missing_and_test_type_is_ui_test___throws() throws {
        let temporaryFolder = try TemporaryFolder()
        XCTAssertThrowsError(
            _ = try runner.run(
                buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: nil, runner: "", xcTestBundle: "", additionalApplicationBundles: []),
                developerDirLocator: FakeDeveloperDirLocator(),
                entriesToRun: [TestEntryFixtures.testEntry()],
                simulator: SimulatorFixture.simulator(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                temporaryFolder: temporaryFolder,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: self,
                testTimeoutConfiguration: testTimeoutConfiguration,
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
                simulator: SimulatorFixture.simulator(),
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                temporaryFolder: temporaryFolder,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: self,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testType: .uiTest
            )
        )
    }
    
    func testStarted(testName: TestName) {}
    
    func caughtException(testException: TestException) {}
    
    func testStopped(testStoppedEvent: TestStoppedEvent) {}
}

