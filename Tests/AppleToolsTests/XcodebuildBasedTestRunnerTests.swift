import AppleTools
import BuildArtifacts
import DateProvider
import DateProviderTestHelpers
import DeveloperDirLocator
import DeveloperDirLocatorTestHelpers
import FileCache
import Foundation
import Models
import ModelsTestHelpers
import PathLib
import ProcessController
import ProcessControllerTestHelpers
import ResourceLocationResolver
import ResourceLocationResolverTestHelpers
import Runner
import RunnerTestHelpers
import SimulatorPoolModels
import TemporaryStuff
import TestHelpers
import URLResource
import XCTest

final class XcodebuildBasedTestRunnerTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    private let testRunnerStream = AccumulatingTestRunnerStream()
    private let dateProvider = DateProviderFixture(Date(timeIntervalSince1970: 100500))
    private let processControllerProvider = FakeProcessControllerProvider()
    private let resourceLocationResolver = FakeResourceLocationResolver(
        resolvingResult: .directlyAccessibleFile(path: "")
    )
    private lazy var simulator = Simulator(
        testDestination: TestDestinationFixtures.testDestination,
        udid: UDID(value: UUID().uuidString),
        path: assertDoesNotThrow {
            try tempFolder.pathByCreatingDirectories(components: ["simulator"])
        }
    )
    private lazy var testContext = TestContext(
        developerDir: DeveloperDir.current,
        environment: [:],
        simulatorPath: simulator.path.fileUrl,
        simulatorUdid: simulator.udid,
        testDestination: simulator.testDestination
    )
    private lazy var runner = XcodebuildBasedTestRunner(
        dateProvider: dateProvider,
        processControllerProvider: processControllerProvider,
        resourceLocationResolver: resourceLocationResolver
    )
    private lazy var developerDirLocator = FakeDeveloperDirLocator(
        result: tempFolder.absolutePath.appending(component: "xcode.app")
    )
    private let testTimeoutConfiguration = TestTimeoutConfiguration(
        singleTestMaximumDuration: 60,
        testRunnerMaximumSilenceDuration: 60
    )
    private lazy var appBundlePath = tempFolder.absolutePath.appending(component: "appbundle.app")
    private lazy var runnerAppPath = tempFolder.absolutePath.appending(component: "xctrunner.app")
    private lazy var testBundlePath: AbsolutePath = {
        let testBundlePlistPath = assertDoesNotThrow {
            try tempFolder.createFile(
                components: ["xctrunner.app", "PlugIns", "testbundle.xctest"],
                filename: "Info.plist",
                contents: try PropertyListSerialization.data(
                    fromPropertyList: ["CFBundleName": "SomeTestProductName"],
                    format: .xml,
                    options: 0
                )
            )
        }
        return testBundlePlistPath.removingLastComponent
    }()
    private lazy var additionalAppPath = tempFolder.absolutePath.appending(component: "additionalapp.app")
    private lazy var buildArtifacts = BuildArtifacts(
        appBundle: AppBundleLocation(.localFilePath(appBundlePath.pathString)),
        runner: RunnerAppLocation(.localFilePath(runnerAppPath.pathString)),
        xcTestBundle: XcTestBundle(
            location: TestBundleLocation(.localFilePath(testBundlePath.pathString)),
            runtimeDumpKind: .logicTest
        ),
        additionalApplicationBundles: [
            AdditionalAppBundleLocation(.localFilePath(additionalAppPath.pathString)),
        ]
    )
    
    func test___ui_test_arguments() throws {
        let argsValidatedExpectation = expectation(description: "Arguments have been validated")
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            XCTAssertEqual(
                try subprocess.arguments.map { try $0.stringValue() },
                [
                    "/usr/bin/xcrun",
                    "xcodebuild",
                    "-destination", "platform=iOS Simulator,id=" + self.simulator.udid.value,
                    "-xctestrun", try self.pathToXctestrunFile().pathString,
                    "-parallel-testing-enabled", "NO",
                    "test-without-building"
                ]
            )
            
            argsValidatedExpectation.fulfill()
            
            let controller = FakeProcessController(subprocess: subprocess)
            controller.overridedProcessStatus = .terminated(exitCode: 1)
            return controller
        }
        
        assertThrows {
            _ = try runner.run(
                buildArtifacts: buildArtifacts,
                developerDirLocator: developerDirLocator,
                entriesToRun: [
                    TestEntryFixtures.testEntry()
                ],
                simulator: simulator,
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                temporaryFolder: tempFolder,
                testContext: testContext,
                testRunnerStream: testRunnerStream,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testType: .uiTest
            )
        }
        
        wait(for: [argsValidatedExpectation], timeout: 15)
    }
    
    func test___ui_test___test_stream_events() throws {
        let impactQueue = DispatchQueue(label: "impact.queue")
        
        processControllerProvider.creator = { subprocess -> ProcessController in
            let controller = FakeProcessController(subprocess: subprocess)
            
            controller.overridedProcessStatus = .stillRunning
            
            impactQueue.asyncAfter(deadline: .now() + 0.5) {
                controller.broadcastStdout(data: "Test Case '-[ModuleWithTests.TestClassName testMethodName]' started.".data(using: .utf8)!)
                
                impactQueue.asyncAfter(deadline: .now() + 0.5) {
                    controller.broadcastStdout(data: "Test Case '-[ModuleWithTests.TestClassName testMethodName]' failed (42.000 seconds).".data(using: .utf8)!)
                    
                    impactQueue.asyncAfter(deadline: .now() + 0.1) {
                        controller.overridedProcessStatus = .terminated(exitCode: 0)
                    }
                }
            }
            return controller
        }
        
        assertDoesNotThrow {
            _ = try runner.run(
                buildArtifacts: buildArtifacts,
                developerDirLocator: developerDirLocator,
                entriesToRun: [
                    TestEntryFixtures.testEntry()
                ],
                simulator: simulator,
                simulatorSettings: SimulatorSettingsFixtures().simulatorSettings(),
                temporaryFolder: tempFolder,
                testContext: testContext,
                testRunnerStream: testRunnerStream,
                testTimeoutConfiguration: testTimeoutConfiguration,
                testType: .uiTest
            )
        }
        
        guard testRunnerStream.accumulatedData.count == 2 else {
            return XCTFail("Unexpected number of events in test stream")
        }
        
        XCTAssertEqual(
            testRunnerStream.accumulatedData[0],
            Either.left(TestName(className: "TestClassName", methodName: "testMethodName"))
        )
        XCTAssertEqual(
            testRunnerStream.accumulatedData[1],
            Either.right(
                TestStoppedEvent(
                    testName: TestName(className: "TestClassName", methodName: "testMethodName"),
                    result: .failure,
                    testDuration: 42.0,
                    testExceptions: [],
                    testStartTimestamp: dateProvider.currentDate().addingTimeInterval(-42.0).timeIntervalSince1970
                )
            )
        )
    }
    
    private func pathToXctestrunFile() throws -> AbsolutePath {
        let path = self.tempFolder.pathWith(components: ["xctestrun"])
        let contents = try FileManager.default.contentsOfDirectory(atPath: path.pathString)
        let xctestrunFileName: String = contents.first(where: { $0.hasSuffix("xctestrun") }) ?? "NOT_FOUND"
        return path.appending(component: xctestrunFileName)
    }
}
