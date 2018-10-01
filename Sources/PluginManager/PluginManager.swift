import EventBus
import Extensions
import Foundation
import Logging
import ModelFactories
import Models
import ProcessController
import SynchronousWaiter

public final class PluginManager: EventStream {
    private let pluginExecutablePaths: [String]
    public static let pluginBundleExtension = "emceeplugin"
    public static let pluginExecutableName = "Plugin"
    private var processControllers = [ProcessController]()
    private let encoder = JSONEncoder()
    private let environment: [String: String]
    
    public init(
        pluginLocations: [ResourceLocation],
        environment: [String: String] = ProcessInfo.processInfo.environment) throws
    {
        self.pluginExecutablePaths = try PluginManager.pathsForPluginExecutables(pluginLocations: pluginLocations)
        self.encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        self.environment = environment
    }
    
    public static func pathsForPluginExecutables(pluginLocations: [ResourceLocation]) throws -> [String] {
        let bundlePaths = try pathsForPluginBundles(pluginLocations: pluginLocations)
        return bundlePaths.map { path in
            let executablePath = path.appending(pathComponent: PluginManager.pluginExecutableName)
            return executablePath
        }
    }
    
    public static func pathsForPluginBundles(pluginLocations: [ResourceLocation]) throws -> [String] {
        let resolver = ResourceLocationResolver.sharedResolver
        var result = [String]()
        
        for resource in pluginLocations {
            let resolvedPath = try resolver.resolvePath(resourceLocation: resource)
            
            let findPluginBundleExecutable: (String) throws -> () = { path in
                guard path.lastPathComponent.pathExtension == PluginManager.pluginBundleExtension else {
                    throw ValidationError.unexpectedExtension(resource, actual: path.lastPathComponent.pathExtension, expected: PluginManager.pluginBundleExtension)
                }
                let executablePath = path.appending(pathComponent: PluginManager.pluginExecutableName)
                guard FileManager.default.fileExists(atPath: executablePath) else {
                    throw ValidationError.noExecutableFound(resource, expectedLocation: executablePath)
                }
                result.append(path)
            }
            
            switch resolvedPath {
            case .directlyAccessibleFile(let path):
                try findPluginBundleExecutable(path)
            case .contentsOfArchive(let containerPath):
                let availablePlugins = FileManager.default.findFiles(path: containerPath, pathExtension: PluginManager.pluginBundleExtension, defaultValue: [])
                guard !availablePlugins.isEmpty else { throw ValidationError.noPluginsFound(resource) }
                for path in availablePlugins {
                    try findPluginBundleExecutable(path)
                }
            }
        }
        
        return result
    }
    
    public func startPlugins() {
        for path in pluginExecutablePaths {
            log("Starting plugin at '\(path)'", color: .blue)
            let controller = ProcessController(subprocess: Subprocess(arguments: [path], environment: environment))
            controller.start()
            processControllers.append(controller)
        }
    }
    
    private func killPlugins() {
        log("Killing plugins that are still alive", color: .red)
        for controller in processControllers {
            controller.interruptAndForceKillIfNeeded()
        }
        processControllers.removeAll()
    }
    
    private func forEachPluginProcess(work: (ProcessController) throws -> ()) rethrows {
        for controller in processControllers {
            try work(controller)
        }
    }
    
    // MARK: - Event Stream
    
    public func process(event: BusEvent) {
        send(busEvent: event)
        switch event {
        case .didObtainTestingResult(let testingResult):
            didObtain(testingResult: testingResult)
        case .runnerEvent(let event):
            runnerEvent(event)
        case .tearDown:
            tearDown()
        }
    }
    
    private func didObtain(testingResult: TestingResult) {}
    
    private func runnerEvent(_ event: RunnerEvent) {}
    
    private func tearDown() {
        do {
            let tearDownAllowance: TimeInterval = 10.0
            log("Waiting \(tearDownAllowance) seconds for plugins to tear down", color: .blue)
            try SynchronousWaiter.waitWhile(timeout: tearDownAllowance) {
                processControllers.map { $0.isProcessRunning }.contains(true)
            }
            log("All plugins torn down successfully without force killing.", color: .boldBlue)
        } catch {
            killPlugins()
        }
    }
    
    // MARK: - Re-distributing events to the plugins
    
    private func send(busEvent: BusEvent) {
        do {
            log("Broadcasting bus event: \(busEvent)")
            let data = try encoder.encode(busEvent)
            sendData(data)
        } catch {
            log("Failed to get data for \(busEvent) event: \(error)")
        }
    }
    
    private func sendData(_ data: Data) {
        do {
            try forEachPluginProcess { processController in
                try processController.writeToStdIn(data: data)
            }
        } catch {
            log("Failed to send event to plugin: \(error)")
            if let stdinError = error as? StdinError {
                processControllers.avito_removeAll { (element: ProcessController) -> Bool in
                    element.processId == stdinError.processController.processId
                }
                log("Will kill plugin", subprocessName: stdinError.processController.processName, subprocessId: stdinError.processController.processId, color: .yellow)
                stdinError.processController.interruptAndForceKillIfNeeded()
            }
        }
    }
}
