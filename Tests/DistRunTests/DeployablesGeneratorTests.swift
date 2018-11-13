import Basic
import Extensions
import Deployer
@testable import DistRun
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import TempFolder
import XCTest

class DeployablesGeneratorTests: XCTestCase {
    
    var deployables = [PackageName: [DeployableItem]]()
    let defaultBuildArtifacts = BuildArtifactsFixtures.withLocalPaths(
        appBundle: String(#file),
        runner: String(#file),
        xcTestBundle: String(#file),
        additionalApplicationBundles: [String(#file)])
    var tempFolder: TempFolder!
    let resolver = ResourceLocationResolver()
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        XCTAssertNoThrow(tempFolder = try TempFolder())
        var pluginPath: String!
        XCTAssertNoThrow(pluginPath = try self.pathToPlugin())
        let generator = DeployablesGenerator(
            targetAvitoRunnerPath: "AvitoRunner",
            auxiliaryResources: AuxiliaryResources(
                toolResources: ToolResources(
                    fbsimctl: FbsimctlLocation(.localFilePath(#file)),
                    fbxctest: FbxctestLocation(.localFilePath(#file))),
                plugins: [PluginLocation(.localFilePath(pluginPath))]),
            buildArtifacts: defaultBuildArtifacts,
            environmentFilePath: String(#file),
            targetEnvironmentPath: "env.json",
            simulatorSettings: SimulatorSettings(
                simulatorLocalizationSettings: String(#file),
                watchdogSettings: String(#file)),
            targetSimulatorLocalizationSettingsPath: "sim.json",
            targetWatchdogSettingsPath: "wd.json")
        XCTAssertNoThrow(deployables = try generator.deployables())
    }
    
    private func pathToPlugin() throws -> String {
        let binaryPath = try tempFolder.createFile(components: ["TestPlugin.emceeplugin"], filename: "Plugin", contents: nil)
        return binaryPath.parentDirectory.asString
    }
    
    private func filterDeployables(_ packageName: PackageName) -> [DeployableItem] {
        return filterDeployables(packageName, in: self.deployables)
    }
    
    private func filterDeployables(_ packageName: PackageName, in deployables: [PackageName: [DeployableItem]]) -> [DeployableItem] {
        return deployables[packageName] ?? []
    }
    
    func testAvitoRunnerIsPresent() {
        let deployables = filterDeployables(.avitoRunner)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, ProcessInfo.processInfo.executablePath)
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
    
    func testPluginIsPresent() throws {
        let deployables = filterDeployables(.plugin)
        XCTAssertEqual(deployables.count, 1)
        
        let files = deployables[0].files
        let expectedFiles = Set([
            DeployableFile(source: tempFolder.pathWith(components: ["TestPlugin.emceeplugin"]).asString, destination: "TestPlugin.emceeplugin"),
            DeployableFile(source: tempFolder.pathWith(components: ["TestPlugin.emceeplugin", "Plugin"]).asString, destination: "TestPlugin.emceeplugin/Plugin")
            ])
        XCTAssertEqual(files, expectedFiles)
    }
    
    func testOptionalWatchdogAndSimulatorLocalizationSettongs() throws {
        let generator = DeployablesGenerator(
            targetAvitoRunnerPath: "AvitoRunner",
            auxiliaryResources: AuxiliaryResources(
                toolResources: ToolResources(
                    fbsimctl: FbsimctlLocation(.localFilePath(#file)),
                    fbxctest: FbxctestLocation(.localFilePath(#file))),
                plugins: []),
            buildArtifacts: defaultBuildArtifacts,
            environmentFilePath: String(#file),
            targetEnvironmentPath: "env.json",
            simulatorSettings: SimulatorSettings(simulatorLocalizationSettings: nil, watchdogSettings: nil),
            targetSimulatorLocalizationSettingsPath: "sim.json",
            targetWatchdogSettingsPath: "wd.json")
        let deployables = try generator.deployables()
        
        XCTAssertEqual(filterDeployables(.watchdogSettings, in: deployables).count, 0)
        XCTAssertEqual(filterDeployables(.simulatorLocalizationSettings, in: deployables).count, 0)
    }
}
