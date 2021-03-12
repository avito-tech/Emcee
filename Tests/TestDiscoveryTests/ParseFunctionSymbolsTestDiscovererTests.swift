@testable import TestDiscovery
import BuildArtifacts
import DateProvider
import DeveloperDirLocator
import FileSystem
import Foundation
import MetricsExtensions
import ProcessController
import ProcessControllerTestHelpers
import ResourceLocationResolverTestHelpers
import RunnerModels
import RunnerTestHelpers
import SimulatorPoolTestHelpers
import Tmp
import TestHelpers
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import XCTest

final class ParseFunctionSymbolsTestDiscovererTests: XCTestCase {
    func test___empty_test_bundle___discovers_no_tests() {
        let discoverer = createParseFunctionSymbolsTestDiscoverer()
        let discoveredTestEntries = assertDoesNotThrow {
            try discoverer.discoverTestEntries(configuration: configuration)
        }
        XCTAssertEqual(discoveredTestEntries, [])
    }
    
    func test___not_empty_test_bundle___discovers_tests() {
        let discoverer = createParseFunctionSymbolsTestDiscoverer(
            nmOutputData: Data(parseFunctionSymbolsTestData.joined(separator: "\n").utf8)
        )
        let discoveredTestEntries = assertDoesNotThrow {
            try discoverer.discoverTestEntries(configuration: configuration)
        }
        XCTAssertEqual(
            discoveredTestEntries,
            expectedDiscoveredTestEnries
        )
    }
    
    private func createParseFunctionSymbolsTestDiscoverer(
        nmOutputData: Data? = nil
    ) -> ParseFunctionSymbolsTestDiscoverer {
        assertDoesNotThrow {
            let plistContents: [String: Any] = [
                "CFBundleExecutable": executableInsideTestBundle
            ]
            _ = try self.tempFolder.createFile(
                components: [testBundlePathInTempFolder.lastComponent],
                filename: "Info.plist",
                contents: try PropertyListSerialization.data(fromPropertyList: plistContents, format: .binary, options: 0)
            )
        }
        
        return ParseFunctionSymbolsTestDiscoverer(
            developerDirLocator: DefaultDeveloperDirLocator(
                processControllerProvider: DefaultProcessControllerProvider(
                    dateProvider: SystemDateProvider(),
                    fileSystem: LocalFileSystem()
                )
            ),
            logger: .noOp,
            processControllerProvider: FakeProcessControllerProvider { subprocess -> ProcessController in
                XCTAssertEqual(
                    try subprocess.arguments.map { try $0.stringValue() },
                    ["/usr/bin/nm", "-j", "-U", self.testBundlePathInTempFolder.appending(component: self.executableInsideTestBundle).pathString]
                )
                
                let processController = FakeProcessController(subprocess: subprocess)
                processController.onStart { _, unsubscribe in
                    processController.broadcastStdout(data: nmOutputData ?? Data())
                    processController.overridedProcessStatus = .terminated(exitCode: 0)
                    unsubscribe()
                }
                processController.overridedProcessStatus = .terminated(exitCode: 0)
                return processController
            },
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(path: testBundlePathInTempFolder),
            tempFolder: tempFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
    }
    
    private let executableInsideTestBundle = "ExecutableInsideTestBundle"
    private let uniqueIdentifierGenerator = FixedValueUniqueIdentifierGenerator(value: UUID().uuidString)
    private lazy var tempFolder: TemporaryFolder = assertDoesNotThrow { try TemporaryFolder() }
    private lazy var testBundlePathInTempFolder = tempFolder.absolutePath.appending(component: "bundle.xctest")
    private lazy var testBundleLocation = TestBundleLocation(.localFilePath(testBundlePathInTempFolder.pathString))
    private lazy var configuration = TestDiscoveryConfiguration(
        analyticsConfiguration: AnalyticsConfiguration(),
        developerDir: .current,
        pluginLocations: [],
        testDiscoveryMode: .parseFunctionSymbols,
        simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
        simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
        testDestination: TestDestinationFixtures.testDestination,
        testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
        testRunnerTool: .xcodebuild,
        testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
        testsToValidate: [],
        xcTestBundleLocation: testBundleLocation,
        persistentMetricsJobId: "",
        remoteCache: NoOpRuntimeDumpRemoteCache()
    )
}
