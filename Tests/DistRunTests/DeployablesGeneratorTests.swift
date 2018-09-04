import Extensions
import Deployer
@testable import DistRun
import Models
import XCTest

class DeployablesGeneratorTests: XCTestCase {
    
    var deployables = [PackageName: [DeployableItem]]()
    
    override func setUp() {
        super.setUp()
        
        let buildArtifacts = BuildArtifacts(
            appBundle: String(#file),
            runner: String(#file),
            xcTestBundle: String(#file),
            additionalApplicationBundles: [String(#file)])
        let generator = DeployablesGenerator(
            targetAvitoRunnerPath: "AvitoRunner",
            auxiliaryPaths: AuxiliaryPaths(fbxctest: String(#file), fbsimctl: String(#file), tempFolder: ""),
            buildArtifacts: buildArtifacts,
            environmentFilePath: String(#file),
            targetEnvironmentPath: "env.json",
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: String(#file),
                watchdogSettings: String(#file)),
            targetSimulatorLocalizationSettingsPath: "sim.json",
            targetWatchdogSettingsPath: "wd.json")
        do {
            self.deployables = try generator.deployables()
        } catch {
            self.continueAfterFailure = false
            XCTFail("Failed to generate deployables: \(error)")
        }
    }
    
    private func filterDeployables(_ packageName: PackageName) -> [DeployableItem] {
        return deployables[packageName] ?? []
    }
    
    func testAvitoRunnerIsPresent() {
        let deployables = filterDeployables(.avitoRunner)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, ProcessInfo.processInfo.arguments[0])
        XCTAssertEqual(deployables[0].files.first?.destination, "AvitoRunner")
    }
    
    func testXctestBundleIsPresent() {
        let deployables = filterDeployables(.xctestBundle)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, String(#file).lastPathComponent)
    }
    
    func testFbxctestIsPresent() {
        let deployables = filterDeployables(.fbxctest)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, String(#file).lastPathComponent)
    }
    
    func testFbsimctlIsPresent() {
        let deployables = filterDeployables(.fbsimctl)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, String(#file).lastPathComponent)
    }
    
    func testAppIsPresent() {
        let deployables = filterDeployables(.app)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, String(#file).lastPathComponent)
    }
    
    func testAdditionalAppIsPresent() {
        let deployables = filterDeployables(.additionalApp)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, String(#file).lastPathComponent)

    }
    
    func testTestRunnerAppIsPresent() {
        let deployables = filterDeployables(.testRunner)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, String(#file).lastPathComponent)
    }
    
    func testEnvironmentIsPresent() {
        let environmentDeployables = filterDeployables(.environment)
        XCTAssertEqual(environmentDeployables.count, 1)
        XCTAssertEqual(environmentDeployables[0].files.first?.source, String(#file))
        XCTAssertEqual(environmentDeployables[0].files.first?.destination, "env.json")
    }
    
    func testSimulatorSettingsIsPresent() {
        let deployables = filterDeployables(.simulatorLocalizationSettings)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, "sim.json")
    }
    
    func testWatchdogSettingsIsPresent() throws {
        let deployables = filterDeployables(.watchdogSettings)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, String(#file))
        XCTAssertEqual(deployables[0].files.first?.destination, "wd.json")
    }
}
