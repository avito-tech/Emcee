import DateProvider
import EventBus
import FileSystem
import PathLib
import PluginManager
import PluginSupport
import ProcessController
import ProcessControllerTestHelpers
import ResourceLocation
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import TemporaryStuff
import TestHelpers
import XCTest

final class PluginManagerTests: XCTestCase {
    var testingPluginExecutablePath = TestingPluginExecutable.testingPluginPath!
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder(deleteOnDealloc: true) }
    lazy var resolver = FakeResourceLocationResolver(
        resolvingResult: ResolvingResult.directlyAccessibleFile(path: tempFolder.absolutePath)
    )
    lazy var fileSystem = LocalFileSystem()
    
    func testStartingPluginWithinBundleButWithWrongExecutableNameFails() throws {
        let pluginBundlePath = tempFolder.absolutePath.appending(component: "MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(component: "WrongExecutableName")
        
        try FileManager.default.createDirectory(atPath: pluginBundlePath)
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.pathString
        )
        
        resolver.resolveWithResult(
            resolvingResult: .directlyAccessibleFile(path: pluginBundlePath)
        )
        
        let manager = PluginManager(
            fileSystem: fileSystem,
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.pathString))
            ],
            processControllerProvider: FakeProcessControllerProvider(tempFolder: tempFolder),
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
            fileSystem: fileSystem,
            pluginLocations: [
                PluginLocation(.localFilePath(executablePath.pathString))
            ],
            processControllerProvider: FakeProcessControllerProvider(tempFolder: tempFolder),
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
            resolvingResult: .directlyAccessibleFile(path: pluginBundlePath)
        )
        
        let manager = PluginManager(
            fileSystem: fileSystem,
            pluginLocations: [
                PluginLocation(.localFilePath(pluginBundlePath.pathString))
            ],
            processControllerProvider: DefaultProcessControllerProvider(
                dateProvider: SystemDateProvider(),
                fileSystem: fileSystem
            ),
            resourceLocationResolver: resolver
        )
        try manager.startPlugins()
        
        let runnerEvent = RunnerEvent.willRun(
            testEntries: [TestEntryFixtures.testEntry()],
            testContext: TestContextFixtures(
                environment: ["EMCEE_TEST_PLUGIN_OUTPUT": outputPath.absolutePath.pathString]
            ).testContext
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
