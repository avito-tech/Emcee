import BuildArtifacts
import BuildArtifactsTestHelpers
import EmceeLib
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestDiscovery
import XCTest

final class TestEntriesValidatorTests: XCTestCase {
    let testDiscoveryQuerier = TestDiscoveryQuerierMock()

    func test__pass_arguments_to_querier() throws {
        let testArgFileEntry = try createTestEntry(testType: .uiTest)
        let validator = createValidator(testArgFileEntries: [testArgFileEntry])

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = testDiscoveryQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }

        XCTAssertEqual(querierConfiguration.testDiscoveryMode, .runtimeLogicTest(testArgFileEntry.simulatorControlTool))
        XCTAssertEqual(querierConfiguration.testRunnerTool, TestRunnerToolFixtures.fakeFbxctestTool)
        XCTAssertEqual(querierConfiguration.xcTestBundleLocation, testArgFileEntry.buildArtifacts.xcTestBundle.location)
        XCTAssertEqual(querierConfiguration.testDestination, testArgFileEntry.testDestination)
        XCTAssertEqual(querierConfiguration.testsToValidate.count, 1)
    }

    func test__dont_pass_app_test_data__if_no_app_tests_in_configuration() throws {
        let uiTestEntry = try createTestEntry(testType: .uiTest)
        let validator = createValidator(testArgFileEntries: [uiTestEntry])

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = testDiscoveryQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }
        XCTAssertEqual(querierConfiguration.testDiscoveryMode, .runtimeLogicTest(uiTestEntry.simulatorControlTool))
    }

    func test__pass_app_test_data__if_flag_is_true() throws {
        let buildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts(testDiscoveryMode: .runtimeAppTest)
        let appTestEntry = try createTestEntry(testType: .appTest, buildArtifacts: buildArtifacts)
        let validator = createValidator(testArgFileEntries: [appTestEntry])
        let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = testDiscoveryQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }

        XCTAssertEqual(
            querierConfiguration.testDiscoveryMode,
            .runtimeAppTest(
                RuntimeDumpApplicationTestSupport(
                    appBundle: fakeBuildArtifacts.appBundle!,
                    simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool
                )
            )
        )
    }

    func test__throws_error__if_app_is_not_provided_for_app_tests() throws {
        let appTestEntry = try createTestEntry(
            testType: .appTest,
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(
                appBundleLocation: nil,
                testDiscoveryMode: .runtimeAppTest
            )
        )
        let validator = createValidator(testArgFileEntries: [appTestEntry])

        XCTAssertThrowsError(_ = try validator.validatedTestEntries { _, _ in })
    }

    func test__querier_called_several_times__if_configuration_contains_several_build_artifacts() throws {
        let appTestEntry1 = try createTestEntry(testType: .appTest, buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(appBundleLocation: "/App1"))
        let appTestEntry2 = try createTestEntry(testType: .appTest, buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(appBundleLocation: "/App2"))
        let validator = createValidator(testArgFileEntries: [appTestEntry1, appTestEntry2])

        _ = try validator.validatedTestEntries { _, _ in }

        XCTAssertEqual(testDiscoveryQuerier.numberOfCalls, 2)
    }

    private func createValidator(
        testArgFileEntries: [TestArgFileEntry]
    ) -> TestEntriesValidator {
        return TestEntriesValidator(
            testArgFileEntries: testArgFileEntries,
            testDiscoveryQuerier: testDiscoveryQuerier,
            persistentMetricsJobId: ""
        )
    }

    private func createTestEntry(
        testType: TestType,
        buildArtifacts: BuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    ) throws -> TestArgFileEntry {
        return TestArgFileEntry(
            buildArtifacts: buildArtifacts,
            developerDir: .current,
            environment: [:],
            numberOfRetries: 1,
            pluginLocations: [],
            scheduleStrategy: .unsplit,
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
            simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: try TestDestination(deviceType: "iPhoneXL", runtime: "10.3"),
            testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
            testType: testType,
            testsToRun: [.testName(TestName(className: "MyTest", methodName: "test"))],
            workerCapabilityRequirements: []
        )
    }
}
