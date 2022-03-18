import CommonTestModelsTestHelpers
import DateProvider
import EventBus
import EmceeExtensions
import FileSystem
import PathLib
import PluginManager
import PluginSupport
import ProcessController
import ProcessControllerTestHelpers
import ResourceLocation
import ResourceLocationResolverTestHelpers
import RunnerTestHelpers
import Tmp
import TestHelpers
import XCTest

final class PluginManagerTests: XCTestCase {
    var testingPluginExecutablePath = TestingPluginExecutable.testingPluginPath!
    lazy var tempFolder = assertDoesNotThrow { try TemporaryFolder(deleteOnDealloc: true) }
    lazy var resolver = FakeResourceLocationResolver(
        resolvingResult: ResolvingResult.directlyAccessibleFile(path: tempFolder.absolutePath)
    )
    lazy var fileSystem = LocalFileSystemProvider().create()
    
    func testStartingPluginWithinBundleButWithWrongExecutableNameFails() throws {
        let pluginBundlePath = tempFolder.absolutePath.appending("MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending("WrongExecutableName")
        
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
            logger: .noOp,
            hostname: "localhost",
            pluginLocations: [
                AppleTestPluginLocation(.localFilePath(pluginBundlePath.pathString))
            ],
            processControllerProvider: FakeProcessControllerProvider(),
            resourceLocationResolver: resolver
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testStartingPluginWithoutBundleFails() throws {
        let executablePath = tempFolder.absolutePath.appending(PluginManager.pluginExecutableName)
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.pathString
        )
        let manager = PluginManager(
            fileSystem: fileSystem,
            logger: .noOp,
            hostname: "localhost",
            pluginLocations: [
                AppleTestPluginLocation(.localFilePath(executablePath.pathString))
            ],
            processControllerProvider: FakeProcessControllerProvider(),
            resourceLocationResolver: resolver
        )
        XCTAssertThrowsError(try manager.startPlugins())
    }
    
    func testExecutingPlugins() throws {
        let pluginBundlePath = tempFolder.absolutePath.appending("MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(PluginManager.pluginExecutableName)
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
            logger: .noOp,
            hostname: "localhost",
            pluginLocations: [
                AppleTestPluginLocation(.localFilePath(pluginBundlePath.pathString))
            ],
            processControllerProvider: DefaultProcessControllerProvider(
                dateProvider: SystemDateProvider(),
                filePropertiesProvider: FilePropertiesProviderImpl()
            ),
            resourceLocationResolver: resolver
        )
        try manager.startPlugins()
        
        let runnerEvent = AppleRunnerEvent.willRun(
            testEntries: [TestEntryFixtures.testEntry()],
            testContext: AppleTestContextFixtures(
                environment: ["EMCEE_TEST_PLUGIN_OUTPUT": outputPath.absolutePath.pathString]
            ).testContext
        )
        
        let eventBus = EventBus()
        eventBus.add(stream: manager)
        eventBus.post(event: .appleRunnerEvent(runnerEvent))
        eventBus.tearDown()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: outputPath.absolutePath.pathString))
        let runnerEventCapturedByPlugin = try JSONDecoder().decode(AppleRunnerEvent.self, from: data)
        
        XCTAssertEqual(runnerEventCapturedByPlugin, runnerEvent)
    }
}
