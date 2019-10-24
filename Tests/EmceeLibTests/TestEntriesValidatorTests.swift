import EmceeLib
import Models
import ModelsTestHelpers
import XCTest

final class TestEntriesValidatorTests: XCTestCase {
    let runtimeTestQuerier = RuntimeTestQuerierMock()

    func test__pass_arguments_to_querier() throws {
        let validatorConfiguration = try createValidatorConfiguration(testArgFileEntries: [createTestEntry(testType: .uiTest)])
        let validator = try createValidator(configuration: validatorConfiguration)

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = runtimeTestQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }

        XCTAssertEqual(querierConfiguration.runtimeDumpMode, .logicTest)
        XCTAssertEqual(querierConfiguration.testRunnerTool, validatorConfiguration.testRunnerTool)
        XCTAssertEqual(querierConfiguration.xcTestBundleLocation, validatorConfiguration.testArgFileEntries[0].buildArtifacts.xcTestBundle.location)
        XCTAssertEqual(querierConfiguration.testDestination, validatorConfiguration.testArgFileEntries[0].testDestination)
        XCTAssertEqual(querierConfiguration.testsToValidate.count, validatorConfiguration.testArgFileEntries.count)
    }

    func test__dont_pass_app_test_data__if_no_app_tests_in_configuration() throws {
        let uiTestEntry = try createTestEntry(testType: .uiTest)
        let validatorConfiguration = try createValidatorConfiguration(testArgFileEntries: [uiTestEntry])
        let validator = try createValidator(configuration: validatorConfiguration)

        _ = try validator.validatedTestEntries { _, _ in }

        guard let querierConfiguration = runtimeTestQuerier.configuration else {
            return XCTFail("configuration is unexpectedly nil")
        }
        XCTAssertEqual(querierConfiguration.runtimeDumpMode, .logicTest)
    }

    func test__pass_app_test_data__if_flag_is_true() throws {
        let buildArtifacts = BuildArtifactsFixtures.fakeEmptyBuildArtifacts(runtimeDumpKind: .appTest)
        let appTestEntry = try createTestEntry(testType: .appTest, buildArtifacts: buildArtifacts)
        let validatorConfiguration = try createValidatorConfiguration(testArgFileEntries: [appTestEntry])
        let validator = try createValidator(configuration: validatorConfiguration)
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
                    simulatorControlTool: validatorConfiguration.simulatorControlTool
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
        let validatorConfiguration = try createValidatorConfiguration(testArgFileEntries: [appTestEntry])
        let validator = try createValidator(configuration: validatorConfiguration)

        XCTAssertThrowsError(_ = try validator.validatedTestEntries { _, _ in })
    }

    func test__querier_called_several_times__if_configuration_contains_several_build_artifacts() throws {
        let appTestEntry1 = try createTestEntry(testType: .appTest, buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(appBundleLocation: "/App1"))
        let appTestEntry2 = try createTestEntry(testType: .appTest, buildArtifacts: BuildArtifactsFixtures.fakeEmptyBuildArtifacts(appBundleLocation: "/App2"))
        let validatorConfiguration = try createValidatorConfiguration(testArgFileEntries: [appTestEntry1, appTestEntry2])
        let validator = try createValidator(configuration: validatorConfiguration)

        _ = try validator.validatedTestEntries { _, _ in }

        XCTAssertEqual(runtimeTestQuerier.numberOfCalls, 2)
    }

    private func createValidator(configuration: TestEntriesValidatorConfiguration) throws -> TestEntriesValidator {
        return TestEntriesValidator(
            validatorConfiguration: configuration,
            runtimeTestQuerier: self.runtimeTestQuerier
        )
    }

    private func createValidatorConfiguration(
        testArgFileEntries: [TestArgFile.Entry],
        simulatorControlTool: SimulatorControlTool = SimulatorControlToolFixtures.fakeFbsimctlTool
    ) throws -> TestEntriesValidatorConfiguration {
        return TestEntriesValidatorConfiguration(
            simulatorControlTool: simulatorControlTool,
            testArgFileEntries: testArgFileEntries,
            testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool
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
            toolchainConfiguration: ToolchainConfiguration(developerDir: .current)
        )
    }
}
