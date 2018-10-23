import Basic
import EventBus
import Models
import PluginManager
import ResourceLocationResolver
import XCTest

final class PluginManagerTests: XCTestCase {
    var testingPluginExecutablePath: String!
    var tempFolder: TemporaryDirectory!
    
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
    
    func testCreatingPluginManagerWithCorrectPluginSuccceds() throws {
        let pluginBundlePath = tempFolder.path.appending(component: "MyPlugin." + PluginManager.pluginBundleExtension)
        let executablePath = pluginBundlePath.appending(component: PluginManager.pluginExecutableName)
        
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: pluginBundlePath.asString),
            withIntermediateDirectories: true)
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath.asString)
        
        
        XCTAssertNoThrow(_ = try PluginManager(
            pluginLocations: [
                ResolvableResourceLocationImpl(resourceLocation: .localFilePath(pluginBundlePath.asString), resolver: ResourceLocationResolver())
            ]))
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
        XCTAssertThrowsError(_ = try PluginManager(
            pluginLocations: [
                ResolvableResourceLocationImpl(resourceLocation: .localFilePath(pluginBundlePath.asString), resolver: ResourceLocationResolver())
            ]))
    }
    
    func testStartingPluginWithoutBundleFails() throws {
        let executablePath = tempFolder.path.appending(component: PluginManager.pluginExecutableName).asString
        try FileManager.default.copyItem(
            atPath: testingPluginExecutablePath,
            toPath: executablePath)
        XCTAssertThrowsError(_ = try PluginManager(
            pluginLocations: [
                ResolvableResourceLocationImpl(resourceLocation: .localFilePath(executablePath), resolver: ResourceLocationResolver())
            ]))
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
            bucket: Bucket(
                bucketId: UUID().uuidString,
                testEntries: [],
                testDestination: try TestDestination(deviceType: "iPhone SE", iOSVersion: "10.3")),
            successfulTests: [],
            failedTests: [],
            unfilteredTestRuns: [])
        let testingResult2 = TestingResult(
            bucket: Bucket(
                bucketId: UUID().uuidString,
                testEntries: [],
                testDestination: try TestDestination(deviceType: "iPhone 7", iOSVersion: "11.3")),
            successfulTests: [],
            failedTests: [],
            unfilteredTestRuns: [])
        
        let manager = try PluginManager(
            pluginLocations: [
                ResolvableResourceLocationImpl(resourceLocation: .localFilePath(pluginBundlePath.asString), resolver: ResourceLocationResolver())
            ],
            environment: ["AVITO_TEST_PLUGIN_OUTPUT": outputPath.path.asString])
        try manager.startPlugins()
        
        let eventBus = EventBus()
        eventBus.add(stream: manager)
        eventBus.post(event: .didObtainTestingResult(testingResult1))
        eventBus.post(event: .didObtainTestingResult(testingResult2))
        eventBus.post(event: .tearDown)
        eventBus.waitForDeliveryOfAllPendingEvents()
        
        let data = try Data(contentsOf: URL(fileURLWithPath: outputPath.path.asString))
        let actualTestingResults: [TestingResult] = try JSONDecoder().decode([TestingResult].self, from: data)
        
        XCTAssertEqual(actualTestingResults.count, 2)
        XCTAssertEqual(actualTestingResults[0].bucket, testingResult1.bucket)
        XCTAssertEqual(actualTestingResults[1].bucket, testingResult2.bucket)
    }
}
