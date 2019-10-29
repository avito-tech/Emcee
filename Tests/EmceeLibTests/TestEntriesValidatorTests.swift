import EmceeLib
import Models
import ModelsTestHelpers
import XCTest

final class TestEntriesValidatorTests: XCTestCase {
    let runtimeTestQuerier = RuntimeTestQuerierMock()

    func test__pass_arguments_to_querier() throws {
        let testArgFileEntry = try createTestEntry(testType: .uiTest)
        let validator = createValidator(testArgFileEntries: [testArgFileEntry])

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = runtimeTestQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }

        XCTAssertEqual(querierConfiguration.runtimeDumpMode, .logicTest)
        XCTAssertEqual(querierConfiguration.testRunnerTool, ToolResourcesFixtures.fakeToolResources().testRunnerTool)
        XCTAssertEqual(querierConfiguration.xcTestBundleLocation, testArgFileEntry.buildArtifacts.xcTestBundle.location)
        XCTAssertEqual(querierConfiguration.testDestination, testArgFileEntry.testDestination)
        XCTAssertEqual(querierConfiguration.testsToValidate.count, 1)
    }

    func test__dont_pass_app_test_data__if_no_app_tests_in_configuration() throws {
        let uiTestEntry = try createTestEntry(testType: .uiTest)
        let validator = createValidator(testArgFileEntries: [uiTestEntry])

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = runtimeTestQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }
        XCTAssertEqual(querierConfiguration.runtimeDumpMode, .logicTest)
    }

    func test__pass_app_test_data__if_flag_is_true() throws {
        let buildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts(runtimeDumpKind: .appTest)
        let appTestEntry = try createTestEntry(testType: .appTest, buildArtifacts: buildArtifacts)
        let validator = createValidator(testArgFileEntries: [appTestEntry])
        let fakeBuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = runtimeTestQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }

        XCTAssertEqual(
            querierConfiguration.runtimeDumpMode,
            .appTest(
                RuntimeDumpApplicationTestSupport(
                    appBundle: fakeBuildArtifacts.appBundle!,
                    simulatorControlTool: ToolResourcesFixtures.fakeToolResources().simulatorControlTool
                )
            )
        )
    }

    func test__throws_error__if_app_is_not_provided_for_app_tests() throws {
        let appTestEntry = try createTestEntry(
            testType: .appTest,
            buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(
                appBundleLocation: nil,
                runtimeDumpKind: .appTest
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

        XCTAssertEqual(runtimeTestQuerier.numberOfCalls, 2)
    }

    private func createValidator(
        testArgFileEntries: [TestArgFile.Entry]
    ) -> TestEntriesValidator {
        return TestEntriesValidator(
            testArgFileEntries: testArgFileEntries,
            runtimeTestQuerier: self.runtimeTestQuerier
        )
    }

    private func createTestEntry(
        testType: TestType,
        buildArtifacts: BuildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts()
    ) throws -> TestArgFile.Entry {
        return TestArgFile.Entry(
            testsToRun: [.testName(TestName(className: "MyTest", methodName: "test"))],
            buildArtifacts: buildArtifacts,
            environment: [:],
            numberOfRetries: 1,
            scheduleStrategy: .unsplit,
            testDestination: try TestDestination(deviceType: "iPhoneXL", runtime: "10.3"),
            testType: testType,
            toolResources: ToolResourcesFixtures.fakeToolResources(),
            toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
        )
    }
}
