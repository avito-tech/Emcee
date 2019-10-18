import AppleTools
import DeveloperDirLocatorTestHelpers
import Foundation
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import TemporaryStuff
import XCTest

final class XcTestRunFileArgumentTests: XCTestCase {
    func test___apptest_requires_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: nil,
                runner: "",
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            developerDirLocator: FakeDeveloperDirLocator(),
            entriesToRun: [],
            resourceLocationResolver: try ResourceLocationResolver(),
            temporaryFolder: try TemporaryFolder(),
            testContext: TestContextFixtures().testContext,
            testType: .appTest
        )
        
        XCTAssertThrowsError(try arg.stringValue())
    }
    
    func test___uitest_requires_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: nil,
                runner: "",
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            developerDirLocator: FakeDeveloperDirLocator(),
            entriesToRun: [],
            resourceLocationResolver: try ResourceLocationResolver(),
            temporaryFolder: try TemporaryFolder(),
            testContext: TestContextFixtures().testContext,
            testType: .uiTest
        )
        
        XCTAssertThrowsError(try arg.stringValue())
    }
    
    func test___uitest_requires_runner_app_bundle() throws {
        let arg = XcTestRunFileArgument(
            buildArtifacts: BuildArtifactsFixtures.withLocalPaths(
                appBundle: "",
                runner: nil,
                xcTestBundle: "",
                additionalApplicationBundles: []
            ),
            developerDirLocator: FakeDeveloperDirLocator(),
            entriesToRun: [],
            resourceLocationResolver: try ResourceLocationResolver(),
            temporaryFolder: try TemporaryFolder(),
            testContext: TestContextFixtures().testContext,
            testType: .uiTest
        )
        
        XCTAssertThrowsError(try arg.stringValue())
    }
}
