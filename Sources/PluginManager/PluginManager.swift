import Basic
import EventBus
import Extensions
import Foundation
import Logging
import Models
import ProcessController
import ResourceLocationResolver
import SynchronousWaiter

public final class PluginManager: EventStream {
    public static let pluginBundleExtension = "emceeplugin"
    public static let pluginExecutableName = "Plugin"
    private let encoder = JSONEncoder()
    private let environment: [String: String]
    private let pluginLocations: [ResolvableResourceLocation]
    private var processControllers = [ProcessController]()
    
    public init(
        pluginLocations: [ResolvableResourceLocation],
        environment: [String: String] = ProcessInfo.processInfo.environment)
        throws
    {
        self.encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        self.environment = environment
        self.pluginLocations = pluginLocations
    }
    
    private static func pathsToPluginBundles(pluginLocations: [ResolvableResourceLocation]) throws -> [AbsolutePath] {
        var paths = [AbsolutePath]()
        for location in pluginLocations {
            let resolvedPath = try location.resolve()
            
            let validatePathToPluginBundle: (String) throws -> () = { path in
                guard path.lastPathComponent.pathExtension == PluginManager.pluginBundleExtension else {
                    throw ValidationError.unexpectedExtension(location, actual: path.lastPathComponent.pathExtension, expected: PluginManager.pluginBundleExtension)
                }
                let executablePath = path.appending(pathComponent: PluginManager.pluginExecutableName)
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: executablePath, isDirectory: &isDir), isDir.boolValue == false else {
                    throw ValidationError.noExecutableFound(location, expectedLocation: executablePath)
                }
                paths.append(try AbsolutePath(validating: path))
            }
            
            switch resolvedPath {
            case .directlyAccessibleFile(let path):
                try validatePathToPluginBundle(path)
            case .contentsOfArchive(let containerPath, let concretePluginName):
                if let concretePluginName = concretePluginName {
                    var path = containerPath.appending(pathComponent: concretePluginName)
                    if path.lastPathComponent.pathExtension != PluginManager.pluginBundleExtension {
                        path = path + "." + PluginManager.pluginBundleExtension
                    }
                    try validatePathToPluginBundle(path)
                } else {
                    let availablePlugins = try FileManager.default.findFiles(path: containerPath, pathExtension: PluginManager.pluginBundleExtension)
                    guard !availablePlugins.isEmpty else { throw ValidationError.noPluginsFound(location) }
                    for path in availablePlugins {
                        try validatePathToPluginBundle(path)
                    }
                }
            }
        }
        return paths
    }
    
    public func startPlugins() throws {
        let pluginBundles = try PluginManager.pathsToPluginBundles(pluginLocations: pluginLocations)
        for bundlePath in pluginBundles {
            log("Starting plugin at '\(bundlePath)'", color: .blue)
            let pluginExecutable = bundlePath.appending(component: PluginManager.pluginExecutableName)
            let controller = try ProcessController(
                subprocess: Subprocess(
                    arguments: [pluginExecutable],
                    environment: environment))
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
