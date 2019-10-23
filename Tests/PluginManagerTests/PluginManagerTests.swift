import EventBus
import Models
import ModelsTestHelpers
import PathLib
import PluginManager
import ResourceLocationResolverTestHelpers
import TemporaryStuff
import XCTest

final class PluginManagerTests: XCTestCase {
    var testingPluginExecutablePath = TestingPluginExecutable.testingPluginPath!
    var tempFolder = try! TemporaryFolder(deleteOnDealloc: true)
    lazy var resolver = FakeResourceLocationResolver(
        resolvingResult: ResolvingResult.directlyAccessibleFile(path: tempFolder.absolutePath.pathString)
    )
    
    func testStartingPluginWithinBundleButWithWrongExecutableNameFails() throws {
        let pluginBundlePath = tempFolder.absolutePath.appending(component: "MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(component: "WrongExecutableName")
        
        try FileManager.default.createDirectory(atPath: pluginBundlePath)
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.pathString
        )
        
        resolver.resolveWithResult(
            resolvingResult: .directlyAccessibleFile(path: pluginBundlePath.pathString)
        )
        
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.pathString))
            ],
            resourceLocationResolver: resolver
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testStartingPluginWithoutBundleFails() throws {
        let executablePath = tempFolder.absolutePath.appending(component: PluginManager.pluginExecutableName)
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.pathString
        )
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(executablePath.pathString))
            ],
            resourceLocationResolver: resolver
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testExecutingPlugins() throws {
        let pluginBundlePath = tempFolder.absolutePath.appending(component: "MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(component: PluginManager.pluginExecutableName)
        let outputPath = try TemporaryFile()
        
        try FileManager.default.createDirectory(atPath: pluginBundlePath)
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.pathString
        )
    
        resolver.resolveWithResult(
            resolvingResult: .directlyAccessibleFile(path: pluginBundlePath.pathString)
        )
        
        let manager = PluginManager(
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.pathString))
            ],
            resourceLocationResolver: resolver
        )
        try manager.startPlugins()
        
        let runnerEvent = RunnerEvent.willRun(
            testEntries: [TestEntryFixtures.testEntry()],
            testContext: TestContext(
                developerDir: .current,
                environment: ["EMCEE_TEST_PLUGIN_OUTPUT": outputPath.absolutePath.pathString],
                simulatorInfo: SimulatorInfo(
                    simulatorUuid: nil,
                    simulatorSetPath: outputPath.absolutePath.pathString,
                    testDestination: TestDestinationFixtures.testDestination
                )
            )
        )
        
        let eventBus = EventBus()
        eventBus.add(stream: manager)
        eventBus.post(event: .runnerEvent(runnerEvent))
        eventBus.tearDown()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: outputPath.absolutePath.pathString))
        let runnerEventCapturedByPlugin = try JSONDecoder().decode(RunnerEvent.self, from: data)
        
        XCTAssertEqual(runnerEventCapturedByPlugin, runnerEvent)
    }
}
