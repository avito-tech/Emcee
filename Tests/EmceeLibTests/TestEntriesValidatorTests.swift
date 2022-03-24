@testable import TestDiscovery
import BuildArtifacts
import BuildArtifactsTestHelpers
import CommonTestModels
import EmceeLib
import MetricsExtensions
import ScheduleStrategy
import SimulatorPoolModels
import SimulatorPoolTestHelpers
import TestArgFile
import TestDestination
import TestDiscovery
import TestHelpers
import XCTest

final class TestEntriesValidatorTests: XCTestCase {
    let testDiscoveryQuerier = TestDiscoveryQuerierMock()

    func test__pass_arguments_to_querier() throws {
        let testArgFileEntry = try createTestEntry()
        let validator = createValidator(testArgFileEntries: [testArgFileEntry])

        _ = try validator.validatedTestEntries(logger: .noOp) { _, _ in }

        let querierConfiguration = assertNotNil {
            testDiscoveryQuerier.configuration
        }

        assert { querierConfiguration.testDiscoveryMode } equals: { .parseFunctionSymbols }
        assert {
            querierConfiguration.testConfiguration.buildArtifacts.xcTestBundle.location
        } equals: {
            testArgFileEntry.buildArtifacts.xcTestBundle.location
        }
        assert {
            querierConfiguration.testConfiguration.simDeviceType
        } equals: {
            try testArgFileEntry.testDestination.simDeviceType()
        }
        assert {
            querierConfiguration.testConfiguration.simRuntime
        } equals: {
            try testArgFileEntry.testDestination.simRuntime()
        }
        assert {
            querierConfiguration.testsToValidate.count
        } equals: {
            1
        }
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
        let buildArtifacts = AppleBuildArtifacts.iosApplicationTests(
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
            buildArtifacts: AppleBuildArtifactsFixture()
                .logicTests(
                    xcTestBundle: XcTestBundleFixture()
                        .with(testDiscoveryMode: .runtimeAppTest)
                        .xcTestBundle()
                )
                .appleBuildArtifacts()
        )
        let validator = createValidator(testArgFileEntries: [appTestEntry])

        XCTAssertThrowsError(_ = try validator.validatedTestEntries(logger: .noOp) { _, _ in })
    }

    func test__querier_called_several_times__if_configuration_contains_several_build_artifacts() throws {
        let appTestEntry1 = try createTestEntry(
            buildArtifacts: AppleBuildArtifactsFixture()
                .logicTests(
                    xcTestBundle: XcTestBundleFixture()
                        .with(localPath: "/bundle1")
                        .xcTestBundle()
                )
                .appleBuildArtifacts()
        )
        let appTestEntry2 = try createTestEntry(
            buildArtifacts: AppleBuildArtifactsFixture()
                .logicTests(
                    xcTestBundle: XcTestBundleFixture()
                        .with(localPath: "/bundle2")
                        .xcTestBundle()
                )
                .appleBuildArtifacts()
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
        buildArtifacts: AppleBuildArtifacts = AppleBuildArtifactsFixture().appleBuildArtifacts()
    ) throws -> TestArgFileEntry {
        return TestArgFileEntry(
            buildArtifacts: buildArtifacts,
            developerDir: .current,
            environment: [:],
            userInsertedLibraries: [],
            numberOfRetries: 1,
            testRetryMode: .retryOnWorker,
            logCapturingMode: .noLogs,
            runnerWasteCleanupPolicy: .clean,
            pluginLocations: [],
            scheduleStrategy: ScheduleStrategy(testSplitterType: .unsplit),
            simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestination.iOSSimulator(deviceType: "iPhoneXL", version: "10.3"),
            testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
            testAttachmentLifetime: .deleteOnSuccess,
            testsToRun: [.testName(TestName(className: "MyTest", methodName: "test"))],
            workerCapabilityRequirements: [],
            resultBundlesUrl: nil
        )
    }
}
