@testable import RuntimeDump
import DeveloperDirLocatorTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import PluginManagerTestHelpers
import ResourceLocationResolver
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import TemporaryStuff
import TestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class RuntimeTestQuerierTests: XCTestCase {
    lazy var developerDirLocator = FakeDeveloperDirLocator(result: tempFolder.absolutePath)
    lazy var fixedValueUniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: dumpFilename)
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    let dumpFilename = UUID().uuidString
    let remoteCache = FakeRuntimeDumpRemoteCache()
    let resourceLocationResolver: ResourceLocationResolver = FakeResourceLocationResolver.throwing()
    let simulatorPool = FakeOnDemandSimulatorPool()
    let testRunnerProvider = FakeTestRunnerProvider()
    
    func test__getting_available_tests__without_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            RuntimeTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.testsInRuntimeDump.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }
    
    func test__getting_available_tests__for_all_available_tests() throws {
        let runtimeTestEntries = [
            RuntimeTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            RuntimeTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [.allProvidedByRuntimeDump],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.testsInRuntimeDump.tests, runtimeTestEntries)
        XCTAssertTrue(queryResult.unavailableTestsToRun.isEmpty)
    }
    
    func test__getting_available_tests_while_some_tests_are_missing__without_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            RuntimeTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.testsInRuntimeDump.tests, runtimeTestEntries)
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
            RuntimeTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            RuntimeTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.testsInRuntimeDump.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }

    func test__getting_available_tests_while_some_tests_are_missing__with_application_test_support() throws {
        let runtimeTestEntries = [
            RuntimeTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            RuntimeTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(queryResult.testsInRuntimeDump.tests, runtimeTestEntries)
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
        let runtimeTestEntries = [RuntimeTestEntryFixtures.entry()]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = runtimeTestQuerier()
        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocationPathForCacheTest"))
        let configuration = runtimeDumpConfiguration(
            testsToValidate: [],
            applicationTestSupport: nil,
            xcTestBundleLocation: xcTestBundleLocation
        )
        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(remoteCache.storedTests, queryResult.testsInRuntimeDump)
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
        remoteCache.testsToReturn = cachedResult.testsInRuntimeDump

        let queryResult = try querier.queryRuntime(configuration: configuration)
        XCTAssertEqual(cachedResult.testsInRuntimeDump, queryResult.testsInRuntimeDump)
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

