import Basic
import EventBus
import Models
import ModelsTestHelpers
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
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.asString
        )
        
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.asString))
            ],
            resourceLocationResolver: resolver
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testStartingPluginWithoutBundleFails() throws {
        let executablePath = tempFolder.path.appending(component: PluginManager.pluginExecutableName).asString
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath
        )
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(executablePath))
            ],
            resourceLocationResolver: resolver
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testExecutingPlugins() throws {
        let pluginBundlePath = tempFolder.path.appending(component: "MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(component: PluginManager.pluginExecutableName)
        let outputPath = try TemporaryFile()
        
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: pluginBundlePath.asString),
            withIntermediateDirectories: true
        )
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.asString
        )
    
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.asString))
            ],
            resourceLocationResolver: resolver
        )
        try manager.startPlugins()
        
        let runnerEvent = RunnerEvent.willRun(
            testEntries: [TestEntryFixtures.testEntry()],
            testContext: TestContext(
                environment: ["AVITO_TEST_PLUGIN_OUTPUT": outputPath.path.asString],
                testDestination: TestDestinationFixtures.testDestination
            )
        )
        
        let eventBus = EventBus()
        eventBus.add(stream: manager)
        eventBus.post(event: .runnerEvent(runnerEvent))
        eventBus.tearDown()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: outputPath.path.asString))
        let runnerEventCapturedByPlugin = try JSONDecoder().decode(RunnerEvent.self, from: data)
        
        XCTAssertEqual(runnerEventCapturedByPlugin, runnerEvent)
    }
}
