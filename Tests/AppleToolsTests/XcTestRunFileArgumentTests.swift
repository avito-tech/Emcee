import AppleTools
import BuildArtifactsTestHelpers
import DeveloperDirLocatorTestHelpers
import Foundation
import QueueModelsTestHelpers
import ResourceLocationResolverTestHelpers
import RunnerModels
import RunnerTestHelpers
import Tmp
import TestHelpers
import XCTest

final class XcTestRunFileArgumentTests: XCTestCase {
    private lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder() }
    
    func test___apptest_requires_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: nil,
                runner: "",
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            entriesToRun: [],
            containerPath: tempFolder.absolutePath,
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(path: tempFolder.absolutePath),
            testContext: TestContextFixtures().testContext,
            testType: .appTest,
            testingEnvironment: XcTestRunTestingEnvironment()
        )
        
        assertThrows { try arg.stringValue() }
    }
    
    func test___uitest_requires_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: nil,
                runner: "",
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            entriesToRun: [],
            containerPath: tempFolder.absolutePath,
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(path: tempFolder.absolutePath),
            testContext: TestContextFixtures().testContext,
            testType: .uiTest,
            testingEnvironment: XcTestRunTestingEnvironment()
        )
        
        assertThrows { try arg.stringValue() }
    }
    
    func test___uitest_requires_runner_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: "",
                runner: nil,
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            entriesToRun: [],
            containerPath: tempFolder.absolutePath,
            resourceLocationResolver: FakeResourceLocationResolver.resolvingTo(path: tempFolder.absolutePath),
            testContext: TestContextFixtures().testContext,
            testType: .uiTest,
            testingEnvironment: XcTestRunTestingEnvironment()
        )
        
        assertThrows { try arg.stringValue() }
    }
}
