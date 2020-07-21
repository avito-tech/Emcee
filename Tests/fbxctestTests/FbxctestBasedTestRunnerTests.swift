import BuildArtifactsTestHelpers
import DeveloperDirLocatorTestHelpers
import ProcessControllerTestHelpers
import ResourceLocationResolverTestHelpers
import Runner
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import TemporaryStuff
import TestHelpers
import XCTest
import fbxctest

final class FbxctestBasedTestRunnerTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private lazy var runner = FbxctestBasedTestRunner(
        fbxctestLocation: FbxctestLocationFixtures.fakeFbxctestLocation,
        processControllerProvider: FakeProcessControllerProvider(tempFolder: tempFolder),
        resourceLocationResolver: FakeResourceLocationResolver.throwing()
    )
    
    func test___when_app_is_missing_and_test_type_is_ui_test___throws() throws {
        let temporaryFolder = try TemporaryFolder()
        XCTAssertThrowsError(
            _ = try runner.prepareTestRun(
                buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: nil, runner: "", xcTestBundle: "", additionalApplicationBundles: []),
                developerDirLocator: FakeDeveloperDirLocator(),
                entriesToRun: [TestEntryFixtures.testEntry()],
                simulator: SimulatorFixture.simulator(),
                temporaryFolder: temporaryFolder,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: AccumulatingTestRunnerStream(),
                testType: .uiTest
            )
        )
    }
    
    func test___when_runner_app_is_missing_and_test_type_is_ui_test___throws() throws {
        let temporaryFolder = try TemporaryFolder()
        XCTAssertThrowsError(
            _ = try runner.prepareTestRun(
                buildArtifacts: BuildArtifactsFixtures.withLocalPaths(appBundle: "", runner: nil, xcTestBundle: "", additionalApplicationBundles: []),
                developerDirLocator: FakeDeveloperDirLocator(),
                entriesToRun: [TestEntryFixtures.testEntry()],
                simulator: SimulatorFixture.simulator(),
                temporaryFolder: temporaryFolder,
                testContext: TestContextFixtures().testContext,
                testRunnerStream: AccumulatingTestRunnerStream(),
                testType: .uiTest
            )
        )
    }
}

