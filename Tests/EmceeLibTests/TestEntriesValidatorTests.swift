@testable import TestDiscovery
import BuildArtifacts
import BuildArtifactsTestHelpers
import EmceeLib
import MetricsExtensions
import RunnerModels
import RunnerTestHelpers
import ScheduleStrategy
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestDiscovery
import XCTest

final class TestEntriesValidatorTests: XCTestCase {
    let testDiscoveryQuerier = TestDiscoveryQuerierMock()

    func test__pass_arguments_to_querier() throws {
        let testArgFileEntry = try createTestEntry()
        let validator = createValidator(testArgFileEntries: [testArgFileEntry])

        _ = try validator.validatedTestEntries(logger: .noOp) { _, _ in }

        guard let querierConfiguration = testDiscoveryQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }

        XCTAssertEqual(querierConfiguration.testDiscoveryMode, .parseFunctionSymbols)
        XCTAssertEqual(querierConfiguration.xcTestBundleLocation, testArgFileEntry.buildArtifacts.xcTestBundle.location)
        XCTAssertEqual(querierConfiguration.testDestination, testArgFileEntry.testDestination)
        XCTAssertEqual(querierConfiguration.testsToValidate.count, 1)
    }

    func test__dont_pass_app_test_data__if_no_app_tests_in_configuration() throws {
        let uiTestEntry = try createTestEntry()
        let validator = createValidator(testArgFileEntries: [uiTestEntry])

        _ = try validator.validatedTestEntries(logger: .noOp) { _, _ in }

        guard let querierConfiguration = testDiscoveryQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }
        XCTAssertEqual(querierConfiguration.testDiscoveryMode, .parseFunctionSymbols)
    }

    func test__pass_app_test_data__if_flag_is_true() throws {
        let appBundleLocation = AppBundleLocation(.localFilePath("/app"))
        let buildArtifacts = BuildArtifacts.iosApplicationTests(
            xcTestBundle: XcTestBundle(
                location: TestBundleLocation(.localFilePath("/bundle")),
                testDiscoveryMode: .runtimeAppTest
            ),
            appBundle: appBundleLocation
        )
        let appTestEntry = try createTestEntry(buildArtifacts: buildArtifacts)
        let validator = createValidator(testArgFileEntries: [appTestEntry])

        _ = try validator.validatedTestEntries(logger: .noOp) { _, _ in }

        guard let querierConfiguration = testDiscoveryQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }

        XCTAssertEqual(
            querierConfiguration.testDiscoveryMode,
            .runtimeAppTest(
                RuntimeDumpApplicationTestSupport(
                    appBundle: appBundleLocation
                )
            )
        )
    }

    func test__throws_error__if_app_is_not_provided_for_app_tests() throws {
        let appTestEntry = try createTestEntry(
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(
                testDiscoveryMode: .runtimeAppTest
            )
        )
        let validator = createValidator(testArgFileEntries: [appTestEntry])

        XCTAssertThrowsError(_ = try validator.validatedTestEntries(logger: .noOp) { _, _ in })
    }

    func test__querier_called_several_times__if_configuration_contains_several_build_artifacts() throws {
        let appTestEntry1 = try createTestEntry(
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(testBundlePath: "/bundle1")
        )
        let appTestEntry2 = try createTestEntry(
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(testBundlePath: "/bundle2")
        )
        let validator = createValidator(testArgFileEntries: [appTestEntry1, appTestEntry2])

        _ = try validator.validatedTestEntries(logger: .noOp) { _, _ in }

        XCTAssertEqual(testDiscoveryQuerier.numberOfCalls, 2)
    }

    private func createValidator(
        testArgFileEntries: [TestArgFileEntry]
    ) -> TestEntriesValidator {
        return TestEntriesValidator(
            remoteCache: NoOpRuntimeDumpRemoteCache(),
            testArgFileEntries: testArgFileEntries,
            testDiscoveryQuerier: testDiscoveryQuerier,
            analyticsConfiguration: AnalyticsConfiguration()
        )
    }

    private func createTestEntry(
        buildArtifacts: BuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    ) throws -> TestArgFileEntry {
        return TestArgFileEntry(
            buildArtifacts: buildArtifacts,
            developerDir: .current,
            environment: [:],
            numberOfRetries: 1,
            testRetryMode: .retryOnWorker,
            pluginLocations: [],
            scheduleStrategy: ScheduleStrategy(testSplitterType: .unsplit),
            simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: try TestDestination(deviceType: "iPhoneXL", runtime: "10.3"),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
            testsToRun: [.testName(TestName(className: "MyTest", methodName: "test"))],
            workerCapabilityRequirements: []
        )
    }
}
