@testable import TestDiscovery
import BuildArtifacts
import DateProviderTestHelpers
import DeveloperDirLocatorTestHelpers
import DeveloperDirModels
import FileSystemTestHelpers
import Foundation
import MetricsTestHelpers
import PluginManagerTestHelpers
import ProcessController
import ProcessControllerTestHelpers
import QueueModels
import ResourceLocation
import ResourceLocationResolver
import ResourceLocationResolverTestHelpers
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import SynchronousWaiter
import TemporaryStuff
import TestArgFile
import TestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class TestDiscoveryQuerierTests: XCTestCase {
    lazy var developerDirLocator = FakeDeveloperDirLocator(result: tempFolder.absolutePath)
    lazy var fixedValueUniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: dumpFilename)
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var fileSystem = FakeFileSystem(rootPath: tempFolder.absolutePath)
    lazy var dumpFilename = UUID().uuidString
    lazy var remoteCache = FakeRuntimeDumpRemoteCache()
    lazy var resourceLocationResolver: ResourceLocationResolver = FakeResourceLocationResolver.throwing()
    lazy var simulatorPool = FakeOnDemandSimulatorPool()
    lazy var testRunnerProvider = FakeTestRunnerProvider(tempFolder: tempFolder)
    lazy var version = Version(value: "version")
    
    func test__getting_available_tests__without_application_test_support() throws {
        let runtimeTestEntries = [
            DiscoveredTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            DiscoveredTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [],
            applicationTestSupport: nil
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(queryResult.discoveredTests.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }
    
    func test__getting_available_tests__for_all_available_tests() throws {
        let runtimeTestEntries = [
            DiscoveredTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            DiscoveredTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [.allDiscoveredTests],
            applicationTestSupport: nil
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(queryResult.discoveredTests.tests, runtimeTestEntries)
        XCTAssertTrue(queryResult.unavailableTestsToRun.isEmpty)
    }
    
    func test__getting_available_tests_while_some_tests_are_missing__without_application_test_support() throws {
        let runtimeTestEntries = [
            DiscoveredTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            DiscoveredTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(queryResult.discoveredTests.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }
    
    func test__when_JSON_file_is_missing_throws__without_application_test_support() throws {
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        XCTAssertThrowsError(_ = try querier.query(configuration: configuration))
    }
    
    func test__when_JSON_file_has_incorrect_format_throws__without_application_test_support() throws {
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: Data("oopps".utf8)
        )
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: nil
        )
        XCTAssertThrowsError(_ = try querier.query(configuration: configuration))
    }

    func test__getting_available_tests__with_application_test_support() throws {
        let runtimeTestEntries = [
            DiscoveredTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            DiscoveredTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(queryResult.discoveredTests.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [])
    }

    func test__getting_available_tests_while_some_tests_are_missing__with_application_test_support() throws {
        let runtimeTestEntries = [
            DiscoveredTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            DiscoveredTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(queryResult.discoveredTests.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }

    func test__when_JSON_file_is_missing_throws__with_application_test_support() throws {
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        XCTAssertThrowsError(_ = try querier.query(configuration: configuration))
    }

    func test__when_JSON_file_has_incorrect_format_throws__with_application_test_support() throws {
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: Data("oopps".utf8)
        )
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport()
        )
        XCTAssertThrowsError(_ = try querier.query(configuration: configuration))
    }

    func test__result_is_stored__when_query_is_successful() throws {
        let runtimeTestEntries = [DiscoveredTestEntryFixtures.entry()]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)

        let querier = testDiscoveryQuerier()
        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocationPathForCacheTest"))
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [],
            applicationTestSupport: nil,
            xcTestBundleLocation: xcTestBundleLocation
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(remoteCache.storedTests, queryResult.discoveredTests)
        XCTAssertEqual(remoteCache.storedXcTestBundleLocation, xcTestBundleLocation)
    }

    func test__runner_is_not_called__with_data_in_remote_cache() throws {
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: Data("oopps".utf8)
        )
        let querier = testDiscoveryQuerier()

        let xcTestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath("xcTestBundleLocationPathForCacheTest"))
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))],
            applicationTestSupport: buildApplicationTestSupport(),
            xcTestBundleLocation: xcTestBundleLocation
        )

        let cachedResult = TestDiscoveryResultFixtures.queryResult()
        remoteCache.resultsXcTestBundleLocation = xcTestBundleLocation
        remoteCache.testsToReturn = cachedResult.discoveredTests

        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(cachedResult.discoveredTests, queryResult.discoveredTests)
        XCTAssertFalse(testRunnerProvider.predefinedFakeTestRunner.isRunCalled)
    }
    
    private func prepareFakeRuntimeDumpOutputForTestQuerier(entries: [DiscoveredTestEntry]) throws {
        let data = try JSONEncoder().encode(entries)
        try tempFolder.createFile(
            filename: dumpFilename,
            contents: data
        )
    }
    
    private func testDiscoveryQuerier() -> TestDiscoveryQuerier {
        return TestDiscoveryQuerierImpl(
            dateProvider: DateProviderFixture(),
            developerDirLocator: developerDirLocator,
            fileSystem: fileSystem,
            metricRecorder: NoOpMetricRecorder(),
            onDemandSimulatorPool: simulatorPool,
            pluginEventBusProvider: NoOoPluginEventBusProvider(),
            processControllerProvider: FakeProcessControllerProvider(tempFolder: tempFolder),
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            uniqueIdentifierGenerator: fixedValueUniqueIdentifierGenerator,
            version: version,
            waiter: SynchronousWaiter()
        )
    }
    
    private func testDiscoveryConfiguration(
        testsToValidate: [TestToRun],
        applicationTestSupport: RuntimeDumpApplicationTestSupport?,
        xcTestBundleLocation: TestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath(""))
    ) -> TestDiscoveryConfiguration {
        return TestDiscoveryConfiguration(
            developerDir: DeveloperDir.current,
            pluginLocations: [],
            testDiscoveryMode: .runtimeLogicTest(applicationTestSupport?.simulatorControlTool ?? SimulatorControlToolFixtures.fakeFbsimctlTool),
            simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
            simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
            testDestination: TestDestinationFixtures.testDestination,
            testExecutionBehavior: TestExecutionBehavior(environment: [:], numberOfRetries: 0),
            testRunnerTool: TestRunnerToolFixtures.fakeFbxctestTool,
            testTimeoutConfiguration: TestTimeoutConfiguration(
                singleTestMaximumDuration: 10,
                testRunnerMaximumSilenceDuration: 10
            ),
            testsToValidate: testsToValidate,
            xcTestBundleLocation: xcTestBundleLocation,
            persistentMetricsJobId: "",
            remoteCache: remoteCache
        )
    }

    private func buildApplicationTestSupport() -> RuntimeDumpApplicationTestSupport {
        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(.localFilePath("")),
            simulatorControlTool: SimulatorControlToolFixtures.fakeFbsimctlTool
        )
    }
}

