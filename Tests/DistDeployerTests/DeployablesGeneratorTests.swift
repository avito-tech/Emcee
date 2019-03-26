import Basic
import Extensions
import Deployer
@testable import DistDeployer
import Models
import ModelsTestHelpers
import ResourceLocationResolver
import TempFolder
import XCTest

class DeployablesGeneratorTests: XCTestCase {
    
    var deployables = [PackageName: [DeployableItem]]()
    var tempFolder: TempFolder!
    let resolver = ResourceLocationResolver()
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        XCTAssertNoThrow(tempFolder = try TempFolder())
        var pluginPath: String!
        XCTAssertNoThrow(pluginPath = try self.pathToPlugin())
        let generator = DeployablesGenerator(
            remoteAvitoRunnerPath: "AvitoRunner",
            pluginLocations: [PluginLocation(.localFilePath(pluginPath))]
        )
        XCTAssertNoThrow(deployables = try generator.deployables())
    }
    
    private func pathToPlugin() throws -> String {
        let binaryPath = try tempFolder.createFile(components: ["TestPlugin.emceeplugin"], filename: "Plugin", contents: nil)
        return binaryPath.parentDirectory.pathString
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
    
    func testPluginIsPresent() throws {
        let deployables = filterDeployables(.plugin)
        XCTAssertEqual(deployables.count, 1)
        
        let files = deployables[0].files
        let expectedFiles = Set([
            DeployableFile(source: tempFolder.pathWith(components: ["TestPlugin.emceeplugin"]).pathString, destination: "TestPlugin.emceeplugin"),
            DeployableFile(source: tempFolder.pathWith(components: ["TestPlugin.emceeplugin", "Plugin"]).pathString, destination: "TestPlugin.emceeplugin/Plugin")
            ])
        XCTAssertEqual(files, expectedFiles)
    }
}
