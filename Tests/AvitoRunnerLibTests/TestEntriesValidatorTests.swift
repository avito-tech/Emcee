import XCTest
import AvitoRunnerLib
import Models
import ModelsTestHelpers

final class TestEntriesValidatorTests: XCTestCase {
    var runtimeTestQuerier: RuntimeTestQuerierMock!

    override func setUp() {
        super.setUp()

        runtimeTestQuerier = RuntimeTestQuerierMock()
    }

    override func tearDown() {
        runtimeTestQuerier = nil

        super.tearDown()
    }

    func test__pass_arguments_to_querier() throws {
        let validatorConfiguration = try createValidatorConfiguration()
        let validator = try createValidator(configuration: validatorConfiguration)

        _ = try validator.validatedTestEntries()

        let querierConfiguration = runtimeTestQuerier.configuration
        XCTAssertNotNil(querierConfiguration)
        XCTAssertNil(querierConfiguration!.applicationTestSupport)
        XCTAssertNil(validatorConfiguration.applicationTestSupport)
        XCTAssertEqual(querierConfiguration!.fbxctest, validatorConfiguration.fbxctest)
        XCTAssertEqual(querierConfiguration!.xcTestBundle, validatorConfiguration.xcTestBundle)
        XCTAssertEqual(querierConfiguration!.testDestination, validatorConfiguration.testDestination)
        XCTAssertEqual(querierConfiguration!.testsToRun.count, validatorConfiguration.testEntries.count)
    }

    func test__dont_pass_app_test_data__if_no_app_tests_in_configuration() throws {
        let uiTestEntry = try createTestEntry(testType: .uiTest)
        let validatorConfiguration = try createValidatorConfiguration(
            applicationTestSupport: createApplicationTestSupport(),
            testEntries: [uiTestEntry]
        )
        let validator = try createValidator(configuration: validatorConfiguration)

        _ = try validator.validatedTestEntries()

        let querierConfiguration = runtimeTestQuerier.configuration
        XCTAssertNil(querierConfiguration?.applicationTestSupport)
    }

    func test__pass_app_test_data__if_app_tests_are_in_configuration() throws {
        let appTestEntry = try createTestEntry(testType: .appTest)
        let applicationTestSupport = createApplicationTestSupport()
        let validatorConfiguration = try createValidatorConfiguration(
            applicationTestSupport: applicationTestSupport,
            testEntries: [appTestEntry]
        )
        let validator = try createValidator(configuration: validatorConfiguration)

        _ = try validator.validatedTestEntries()

        let querierConfiguration = runtimeTestQuerier.configuration
        XCTAssertNotNil(querierConfiguration!.applicationTestSupport)
        XCTAssertEqual(querierConfiguration!.applicationTestSupport!, applicationTestSupport)
    }

    func test__throws_error__if_support_data_is_not_provided_for_app_tests() throws {
        let appTestEntry = try createTestEntry(testType: .appTest)
        let validatorConfiguration = try createValidatorConfiguration(
            applicationTestSupport: nil,
            testEntries: [appTestEntry]
        )
        let validator = try createValidator(configuration: validatorConfiguration)

        XCTAssertThrowsError(_ = try validator.validatedTestEntries())
    }

    private func createValidator(configuration: TestEntriesValidatorConfiguration) throws -> TestEntriesValidator {
        return TestEntriesValidator(
            validatorConfiguration: configuration,
            runtimeTestQuerier: self.runtimeTestQuerier
        )
    }

    private func createValidatorConfiguration(
        applicationTestSupport: RuntimeDumpApplicationTestSupport? = nil,
        testEntries: [TestArgFile.Entry] = []) throws -> TestEntriesValidatorConfiguration
    {
        return TestEntriesValidatorConfiguration(
            fbxctest: FbxctestLocation(.localFilePath("/")),
            xcTestBundle: TestBundleLocation(.localFilePath("/")),
            applicationTestSupport: applicationTestSupport,
            testDestination: try TestDestination(deviceType: "iPhone XL", runtime: "10.3"),
            testEntries: testEntries
        )
    }

    private func createApplicationTestSupport() -> RuntimeDumpApplicationTestSupport {
        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(.localFilePath("/")),
            fbsimctl: FbsimctlLocation(.localFilePath("/"))
        )
    }

    private func createTestEntry(testType: TestType) throws -> TestArgFile.Entry {
        return TestArgFile.Entry(
            testToRun: .testName("myTest"),
            environment: [:],
            numberOfRetries: 1,
            testDestination: try TestDestination(deviceType: "iPhoneXL", runtime: "10.3"),
            testType: testType
        )
    }
}
