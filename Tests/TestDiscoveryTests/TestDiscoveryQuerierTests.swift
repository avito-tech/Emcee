import AppleTestModelsTestHelpers
import BuildArtifacts
import BuildArtifactsTestHelpers
import CommonTestModels
import DateProviderTestHelpers
import DeveloperDirLocatorTestHelpers
import FileSystemTestHelpers
import MetricsExtensions
import PluginManagerTestHelpers
import ProcessControllerTestHelpers
import QueueModels
import ResourceLocation
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import SynchronousWaiter
import Tmp
import TestArgFile
import TestDiscovery
import TestHelpers
import UniqueIdentifierGeneratorTestHelpers
import XCTest
import ZipTestHelpers
// TODO: check imports

final class TestDiscoveryQuerierTests: XCTestCase {
    lazy var developerDirLocator = FakeDeveloperDirLocator(result: tempFolder.absolutePath)
    lazy var fixedValueUniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: dumpFilename)
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    lazy var fileSystem = FakeFileSystem(rootPath: tempFolder.absolutePath)
    lazy var dumpFilename = UUID().uuidString
    lazy var remoteCache = FakeRuntimeDumpRemoteCache()
    lazy var resourceLocationResolver = FakeResourceLocationResolver.throwing()
    lazy var simulatorPool = FakeOnDemandSimulatorPool()
    lazy var testRunnerProvider = FakeTestRunnerProvider()
    lazy var version = Version(value: "version")
    
    func test__getting_available_tests__without_application_test_support() throws {
        let runtimeTestEntries = [
            DiscoveredTestEntryFixtures.entry(className: "class1", testMethods: ["test"]),
            DiscoveredTestEntryFixtures.entry(className: "class2", testMethods: ["test1", "test2"])
        ]
        try prepareFakeRuntimeDumpOutputForTestQuerier(entries: runtimeTestEntries)
        
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: []
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
            testsToValidate: [.allDiscoveredTests]
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
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))]
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(queryResult.discoveredTests.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }
    
    func test__when_JSON_file_is_missing_throws__without_application_test_support() throws {
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))]
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
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))]
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
            testsToValidate: []
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
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))]
        )
        let queryResult = try querier.query(configuration: configuration)
        XCTAssertEqual(queryResult.discoveredTests.tests, runtimeTestEntries)
        XCTAssertEqual(queryResult.unavailableTestsToRun, [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))])
    }

    func test__when_JSON_file_is_missing_throws__with_application_test_support() throws {
        let querier = testDiscoveryQuerier()
        let configuration = testDiscoveryConfiguration(
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))]
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
            testsToValidate: [TestToRun.testName(TestName(className: "Class", methodName: "testNonexistingtest"))]
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
            hostname: "hostname",
            globalMetricRecorder: GlobalMetricRecorderImpl(),
            specificMetricRecorderProvider: NoOpSpecificMetricRecorderProvider(),
            onDemandSimulatorPool: simulatorPool,
            pluginEventBusProvider: NoOoPluginEventBusProvider(),
            processControllerProvider: FakeProcessControllerProvider(),
            resourceLocationResolver: resourceLocationResolver,
            runnerWasteCollectorProvider: FakeRunnerWasteCollectorProvider(),
            tempFolder: tempFolder,
            testRunnerProvider: testRunnerProvider,
            uniqueIdentifierGenerator: fixedValueUniqueIdentifierGenerator,
            version: version,
            waiter: SynchronousWaiter()
        )
    }
    
    private func testDiscoveryConfiguration(
        testsToValidate: [TestToRun],
        xcTestBundleLocation: TestBundleLocation = TestBundleLocation(ResourceLocation.localFilePath(""))
    ) -> TestDiscoveryConfiguration {
        return TestDiscoveryConfiguration(
            analyticsConfiguration: AnalyticsConfiguration(),
            logger: .noOp,
            remoteCache: remoteCache,
            testsToValidate: testsToValidate,
            testDiscoveryMode: .runtimeLogicTest,
            testConfiguration: AppleTestConfigurationFixture()
                .with(
                    buildArtifacts: AppleBuildArtifactsFixture()
                        .logicTests(
                            xcTestBundle: XcTestBundle(
                                location: xcTestBundleLocation,
                                testDiscoveryMode: .parseFunctionSymbols
                            )
                        )
                        .appleBuildArtifacts()
                    )
                .appleTestConfiguration()
        )
    }

    private func buildApplicationTestSupport() -> RuntimeDumpApplicationTestSupport {
        return RuntimeDumpApplicationTestSupport(
            appBundle: AppBundleLocation(.localFilePath(""))
        )
    }
}

