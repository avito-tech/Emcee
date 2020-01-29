@testable import RuntimeDump
import DeveloperDirLocatorTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import PluginManagerTestHelpers
import ResourceLocationResolver
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import SimulatorPool
import SimulatorPoolTestHelpers
import TemporaryStuff
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class RuntimeTestQuerierTests: XCTestCase {
    let remoteCache = FakeRuntimeDumpRemoteCache()
    let testRunnerProvider = FakeTestRunnerProvider()
    let resourceLocationResolver: ResourceLocationResolver = FakeResourceLocationResolver.throwing()
    let tempFolder = try! TemporaryFolder()
    let dumpFilename = UUID().uuidString
    lazy var fixedValueUniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: dumpFilename)
    lazy var developerDirLocator = FakeDeveloperDirLocator(result: tempFolder.absolutePath)
    lazy var simulatorPool = OnDemandSimulatorPool(
        developerDirLocator: developerDirLocator,
        resourceLocationResolver: resourceLocationResolver,
        simulatorControllerProvider: FakeSimulatorControllerProvider { testDestination -> SimulatorController in
            return FakeSimulatorController(
                simulator: Simulator(
                    testDestination: testDestination,
                    udid: UDID(value: "fixed_udid"),
                    path: self.tempFolder.absolutePath
                ),
                simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool,
                developerDir: .current
            )
        },
        tempFolder: tempFolder
    )
    
    func test__getting_available_tests__without_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }
    
    func test__getting_available_tests__for_all_available_tests() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [.allProvidedByRuntimeDump],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertTrue(queryResult.unavailableTestsToRun.isEmpty)
    }
    
    func test__getting_available_tests_while_some_tests_are_missing__without_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }
    
    func test__when_JSON_file_is_missing_throws__without_application_test_support() throws {
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }
    
    func test__when_JSON_file_has_incorrect_format_throws__without_application_test_support() throws {
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }

    func test__getting_available_tests__with_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }

    func test__getting_available_tests_while_some_tests_are_missing__with_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: []),
            RuntimeTestEntry(className: "class2", path: "", testMethods: ["test1", "test2"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.availableRuntimeTests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }

    func test__when_JSON_file_is_missing_throws__with_application_test_support() throws {
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }

    func test__when_JSON_file_has_incorrect_format_throws__with_application_test_support() throws {
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        XCTAssertThrowsError(_ = try querier.queryRuntime(configuration: configuration))
    }

    func test__result_is_stored__when_query_is_successful() throws {
        let runtimeTestEntries = [
            RuntimeTestEntry(className: "class1", path: "", testMethods: ["test"], caseId: nil, tags: [])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocationPathForCacheTest"))
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: nil,
            xcTestBundleLocation: xcTestBundleLocation
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(remoteCache.storedResult, queryResult)
        XCTAssertEqual(remoteCache.storedXcTestBundleLocation, xcTestBundleLocation)
    }

    func test__runner_is_not_called__with_data_in_remote_cache() throws {
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: "oopps".data(using: .utf8)!)
        let querier = runtimeTestQuerier()

        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocationPathForCacheTest"))
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport(),
            xcTestBundleLocation: xcTestBundleLocation
        )

        let cachedResult = RuntimeQueryResultFixtures.queryResult()
        remoteCache.resultsXcTestBundleLocation = xcTestBundleLocation
        remoteCache.resultToReturn = cachedResult

        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(cachedResult, queryResult)
        XCTAssertFalse(testRunnerProvider.predefinedFakeTestRunner.isRunCalled)
    }
    
    private func prepareFakeRuntimeDumpOutputForTestQuerier(entries: [RuntimeTestEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: data
        )
    }
    
    private func runtimeTestQuerier() -> RuntimeTestQuerier {
        return RuntimeTestQuerierImpl(
            developerDirLocator: developerDirLocator,
            numberOfAttemptsToPerformRuntimeDump: 1,
            onDemandSimulatorPool: simulatorPool,
            pluginEventBusProvider: NoOoPluginEventBusProvider(),
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            uniqueIdentifierGenerator: fixedValueUniqueIdentifierGenerator,
            remoteCache: remoteCache
        )
    }
    
    private func runtimeDumpConfiguration(
        testsToValidate: [TestToRun],
        applicationTestSupport: RuntimeDumpApplicationTestSupport?,
        xcTestBundleLocation: TestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath(""))
    ) -> RuntimeDumpConfiguration {
        return RuntimeDumpConfiguration(
            developerDir: DeveloperDir.current,
            pluginLocations: [],
            runtimeDumpMode: .logicTest(applicationTestSupport?.simulatorControlTool ?? .simctl),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 0),
            testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
            testTimeoutConfiguration: TestTimeoutConfiguration(
                singleTestMaximumDuration: 10,
                testRunnerMaximumSilenceDuration: 10
            ),
            testsToValidate: testsToValidate,
            xcTestBundleLocation: xcTestBundleLocation
        )
    }

    private func buildApplicationTestSupport() -> RuntimeDumpApplicationTestSupport {
        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(.localFilePath("")),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool
        )
    }
}

