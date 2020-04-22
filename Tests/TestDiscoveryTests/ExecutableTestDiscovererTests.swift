@testable import TestDiscovery
import AppleTools
import BuildArtifacts
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import FileCache
import Foundation
import Logging
import Models
import ModelsTestHelpers
import PathLib
import ProcessController
import ProcessControllerTestHelpers
import ResourceLocation
import ResourceLocationResolver
import ResourceLocationResolverTestHelpers
import SimulatorPoolTestHelpers
import TemporaryStuff
import UniqueIdentifierGenerator
import UniqueIdentifierGeneratorTestHelpers
import URLResource
import XCTest

final class ExecutableTestDiscovererTests: XCTestCase {
    func test___test_discovery___discovers_test_entries___from_executable_response() {
        let discoveredTestEntries = assertDoesNotThrow {
            try createExecutableTestDiscoverer(
                simctlResponse: simctResponse(runtimeName: "iOS 12.0"),
                executableResponse: executableResponse
            ).discoverTestEntries(
                configuration: configuration
            )
        }
        
        XCTAssertEqual(
            discoveredTestEntries,
            expectedTestEntries
        )
    }
    
    func test___test_discovery___throws___when_runtime_is_not_found() {
        assertThrows {
            _ = try createExecutableTestDiscoverer(
                simctlResponse: simctResponse(runtimeName: "nonexistent runtime"),
                executableResponse: executableResponse
            ).discoverTestEntries(
                configuration: configuration
            )
        }
    }
    
    func test___test_discovery___throws___when_output_file_format_is_incorrect() {
        assertThrows {
            _ = try createExecutableTestDiscoverer(
                simctlResponse: simctResponse(runtimeName: "iOS 12.0"),
                executableResponse: """
                [
                    {
                        "not_a_test_entry_key": "not_a_test_entry_value"
                    }
                ]
                """
            ).discoverTestEntries(
                configuration: configuration
            )
        }
    }
    
    func test___simctl_environment___contains_developer_dir() {
        var subprocesses = [Subprocess]()
        
        assertDoesNotThrow {
            _ = try createExecutableTestDiscoverer(
                onSubprocessCreate: { subprocesses.append($0) },
                simctlResponse: simctResponse(runtimeName: "iOS 12.0"),
                executableResponse: executableResponse
            ).discoverTestEntries(
                configuration: configuration
            )
        }
        
        XCTAssertEqual(
            subprocesses[0].environment["DEVELOPER_DIR"],
            "/path/to/developer_dir"
        )
    }
    
    func test___executable_environment___contains_required_variables() {
        var subprocesses = [Subprocess]()
        
        assertDoesNotThrow {
            _ = try createExecutableTestDiscoverer(
                onSubprocessCreate: { subprocesses.append($0) },
                simctlResponse: simctResponse(runtimeName: "iOS 12.0"),
                executableResponse: executableResponse
            ).discoverTestEntries(
                configuration: configuration
            )
        }
        
        XCTAssertEqual(
            subprocesses[1].environment["SIMULATOR_ROOT"],
            "/path/to/iOS 12.0.simruntime/Contents/Resources/RuntimeRoot"
        )
        XCTAssertEqual(
            subprocesses[1].environment["DYLD_ROOT_PATH"],
            "/path/to/iOS 12.0.simruntime/Contents/Resources/RuntimeRoot"
        )
        XCTAssert(
            subprocesses[1].environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"]?.isEmpty == false
        )
        XCTAssert(
            subprocesses[1].environment["EMCEE_RUNTIME_TESTS_EXPORT_PATH"]?.isEmpty == false
        )
        XCTAssertEqual(
            subprocesses[1].environment["EMCEE_XCTEST_BUNDLE_PATH"],
            "/path/to/bundle.xctest"
        )
    }
    
    private func simctResponse(runtimeName: String) -> String {
        return """
        {
          "runtimes": [
            {
              "bundlePath": "\\/path\\/to\\/\(runtimeName).simruntime",
              "name": "\(runtimeName)"
            }
          ]
        }
        """
    }
    
    private var executableResponse: String {
        return """
        [
            {
              "caseId" : 1,
              "path" : "\\/path\\/to\\/test.swift",
              "className" : "Test",
              "testMethods" : [
                "test_method"
              ],
              "tags" : [
                "test_tag"
              ]
            }
        ]
        """
    }
    
    private var expectedTestEntries: [DiscoveredTestEntry] {
        return [
            DiscoveredTestEntry(
                className: "Test",
                path: "/path/to/test.swift",
                testMethods: ["test_method"],
                caseId: 1,
                tags: ["test_tag"]
            )
        ]
    }
    
    private func createExecutableTestDiscoverer(
        onSubprocessCreate: ((Subprocess) -> ())? = nil,
        simctlResponse: String,
        executableResponse: String
    ) -> ExecutableTestDiscoverer {
        return ExecutableTestDiscoverer(
            appBundleLocation: appBundleLocation,
            developerDirLocator: FakeDeveloperDirLocator(result: AbsolutePath("/path/to/developer_dir")),
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(
                path: AbsolutePath(testBundleLocation.resourceLocation.stringValue)
            ),
            processControllerProvider: FakeProcessControllerProvider(creator: { subprocess in
                onSubprocessCreate?(subprocess)
                
                let arguments = try subprocess.arguments.map { try $0.stringValue() }
                if arguments.contains("simctl") {
                    try simctlResponse.write(
                        to: subprocess.standardStreamsCaptureConfig.stdoutContentsFile.fileUrl,
                        atomically: true,
                        encoding: .utf8
                    )
                } else if let outputPath = subprocess.environment["EMCEE_RUNTIME_TESTS_EXPORT_PATH"] {
                    try executableResponse.write(
                        to: AbsolutePath(outputPath).fileUrl,
                        atomically: true,
                        encoding: .utf8
                    )
                }
                
                let processController = FakeProcessController(subprocess: subprocess)
                processController.overridedProcessStatus = .terminated(exitCode: 0)
                return processController
            }),
            tempFolder: assertDoesNotThrow { try TemporaryFolder() },
            uniqueIdentifierGenerator: UuidBasedUniqueIdentifierGenerator()
        )
    }
    
    private let testBundleLocation = TestBundleLocation(
        ResourceLocation.localFilePath(
            "/path/to/bundle.xctest"
        )
    )
    private let appBundleLocation = AppBundleLocation(
        ResourceLocation.localFilePath(
            Bundle.main.bundlePath
        )
    )
    private lazy var configuration = TestDiscoveryConfiguration(
        developerDir: .current,
        pluginLocations: [],
        testDiscoveryMode: .runtimeExecutableLaunch(appBundleLocation),
        simulatorOperationTimeouts: SimulatorOperationTimeoutsFixture().simulatorOperationTimeouts(),
        simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
        testDestination: TestDestinationFixtures.testDestination,
        testExecutionBehavior: TestExecutionBehaviorFixtures().build(),
        testRunnerTool: .xcodebuild,
        testTimeoutConfiguration: TestTimeoutConfiguration(singleTestMaximumDuration: 0, testRunnerMaximumSilenceDuration: 0),
        testsToValidate: [],
        xcTestBundleLocation: testBundleLocation
    )
}
