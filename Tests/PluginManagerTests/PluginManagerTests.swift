import Basic
import EventBus
import Models
import PluginManager
import ResourceLocationResolver
import XCTest

final class PluginManagerTests: XCTestCase {
    var testingPluginExecutablePath: String!
    var tempFolder: TemporaryDirectory!
    let resolver = ResourceLocationResolver()
    
    override func setUp() {
        guard let executablePath = TestingPluginExecutable.testingPluginPath else {
            XCTFail("Unable to build testing plugin")
            return
        }
        guard let temporaryDirectory = try? TemporaryDirectory(removeTreeOnDeinit: true) else {
            XCTFail("Unable to create temp directory")
            return
        }
        testingPluginExecutablePath = executablePath
        tempFolder = temporaryDirectory
    }
    
    func testStartingPluginWithinBundleButWithWrongExecutableNameFails() throws {
        let pluginBundlePath = tempFolder.path.appending(component: "MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(component: "WrongExecutableName")
        
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: pluginBundlePath.asString),
            withIntermediateDirectories: true)
        
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.asString)
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.asString))
            ],
            resourceLocationResolver: resolver,
            environment: [:]
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testStartingPluginWithoutBundleFails() throws {
        let executablePath = tempFolder.path.appending(component: PluginManager.pluginExecutableName).asString
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath)
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(executablePath))
            ],
            resourceLocationResolver: resolver,
            environment: [:]
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testExecutingPlugins() throws {
        let pluginBundlePath = tempFolder.path.appending(component: "MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(component: PluginManager.pluginExecutableName)
        let outputPath = try TemporaryFile()
        
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: pluginBundlePath.asString),
            withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.asString)
        let testingResult1 = TestingResult(
            bucketId: "id1",
            testDestination: try TestDestination(deviceType: "iPhone SE", runtime: "10.3"),
            unfilteredResults: [])
        let testingResult2 = TestingResult(
            bucketId: "id2",
            testDestination: try TestDestination(deviceType: "iPhone 7", runtime: "11.3"),
            unfilteredResults: [])
        
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.asString))
            ],
            resourceLocationResolver: resolver,
            environment: ["AVITO_TEST_PLUGIN_OUTPUT": outputPath.path.asString])
        try manager.startPlugins()
        
        let eventBus = EventBus()
        eventBus.add(stream: manager)
        eventBus.post(event: .didObtainTestingResult(testingResult1))
        eventBus.post(event: .didObtainTestingResult(testingResult2))
        eventBus.tearDown()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: outputPath.path.asString))
        let actualTestingResults: [TestingResult] = try JSONDecoder().decode([TestingResult].self, from: data)
        
        XCTAssertEqual(actualTestingResults.count, 2)
        XCTAssertEqual(actualTestingResults[0].bucketId, testingResult1.bucketId)
        XCTAssertEqual(actualTestingResults[1].bucketId, testingResult2.bucketId)
    }
}
