@testable import DistDeployer
import Deployer
import Extensions
import Models
import ModelsTestHelpers
import PathLib
import ResourceLocationResolver
import TemporaryStuff
import Version
import XCTest

class DeployablesGeneratorTests: XCTestCase {
    
    var deployables = [PackageName: [DeployableItem]]()
    var tempFolder: TemporaryFolder!
    let resolver = ResourceLocationResolver()
    let versionStringValue = "SomeVersion"
    lazy var versionProvider = FixedVersionProvider(value: versionStringValue)
    
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
        XCTAssertNoThrow(tempFolder = try TemporaryFolder())
        var pluginPath: String!
        XCTAssertNoThrow(pluginPath = try self.pathToPlugin())
        let generator = DeployablesGenerator(
            emceeVersionProvider: versionProvider,
            pluginLocations: [PluginLocation(.localFilePath(pluginPath))],
            remoteEmceeBinaryName: "Emcee"
        )
        XCTAssertNoThrow(deployables = try generator.deployables())
    }
    
    private func pathToPlugin() throws -> String {
        let binaryPath = try tempFolder.createFile(components: ["TestPlugin.emceeplugin"], filename: "Plugin", contents: nil)
        return binaryPath.removingLastComponent.pathString
    }
    
    private func filterDeployables(_ packageName: PackageName) -> [DeployableItem] {
        return filterDeployables(packageName, in: self.deployables)
    }
    
    private func filterDeployables(_ packageName: PackageName, in deployables: [PackageName: [DeployableItem]]) -> [DeployableItem] {
        return deployables[packageName] ?? []
    }
    
    func testAvitoRunnerIsPresent() {
        let deployables = filterDeployables(.emceeBinary)
        XCTAssertEqual(deployables.count, 1)
        XCTAssertEqual(deployables[0].files.first?.source, AbsolutePath(ProcessInfo.processInfo.executablePath))
        XCTAssertEqual(deployables[0].files.first?.destination, RelativePath("Emcee_" + versionStringValue))
    }
    
    func testPluginIsPresent() throws {
        let deployables = filterDeployables(.plugin)
        XCTAssertEqual(deployables.count, 1)
        
        let files = deployables[0].files
        let expectedFiles = Set(
            [
                DeployableFile(
                    source: tempFolder.pathWith(components: ["TestPlugin.emceeplugin"]),
                    destination: RelativePath("TestPlugin.emceeplugin")
                ),
                DeployableFile(
                    source: tempFolder.pathWith(components: ["TestPlugin.emceeplugin", "Plugin"]),
                    destination: RelativePath("TestPlugin.emceeplugin/Plugin")
                )
            ]
        )
        XCTAssertEqual(files, expectedFiles)
    }
}

class FixedVersionProvider: VersionProvider {
    let value: String

    public init(value: String) {
        self.value = value
    }
    
    public func version() throws -> Version {
        return Version(value: value)
    }
}
