import EventBus
import Extensions
import Foundation
import Logging
import Models
import PathLib
import ProcessController
import ResourceLocationResolver
import SynchronousWaiter

public final class PluginManager: EventStream {
    public static let pluginBundleExtension = "emceeplugin"
    public static let pluginExecutableName = "Plugin"
    private let encoder = JSONEncoder.pretty()
    private let pluginLocations: [PluginLocation]
    private var processControllers = [ProcessController]()
    private let resourceLocationResolver: ResourceLocationResolver
    private let eventDistributor: EventDistributor
    
    public init(
        pluginLocations: [PluginLocation],
        resourceLocationResolver: ResourceLocationResolver)
    {
        self.pluginLocations = pluginLocations
        self.resourceLocationResolver = resourceLocationResolver
        self.eventDistributor = EventDistributor()
    }
    
    private static func pathsToPluginBundles(
        pluginLocations: [PluginLocation],
        resourceLocationResolver: ResourceLocationResolver
    ) throws -> [AbsolutePath] {
        var paths = [AbsolutePath]()
        for location in pluginLocations {
            let resolvableLocation = resourceLocationResolver.resolvable(withRepresentable: location)
            
            let validatePathToPluginBundle: (String) throws -> () = { path in
                guard path.lastPathComponent.pathExtension == PluginManager.pluginBundleExtension else {
                    throw ValidationError.unexpectedExtension(location, actual: path.lastPathComponent.pathExtension, expected: PluginManager.pluginBundleExtension)
                }
                let executablePath = path.appending(pathComponent: PluginManager.pluginExecutableName)
                var isDir: ObjCBool = false
                guard FileManager.default.fileExists(atPath: executablePath, isDirectory: &isDir), isDir.boolValue == false else {
                    throw ValidationError.noExecutableFound(location, expectedLocation: executablePath)
                }
                paths.append(AbsolutePath(path))
            }
            
            switch try resolvableLocation.resolve() {
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
        try eventDistributor.start()
        let pluginSocket = try eventDistributor.webSocketAddress()
        
        let pluginBundles = try PluginManager.pathsToPluginBundles(
            pluginLocations: pluginLocations,
            resourceLocationResolver: resourceLocationResolver)
        
        for bundlePath in pluginBundles {
            Logger.debug("Starting plugin at '\(bundlePath)'")
            let pluginExecutable = bundlePath.appending(component: PluginManager.pluginExecutableName)
            let pluginIdentifier = try pluginExecutable.pathString.avito_sha256Hash()
            eventDistributor.add(pluginIdentifier: pluginIdentifier)
            let controller = try ProcessController(
                subprocess: Subprocess(
                    arguments: [pluginExecutable],
                    environment: environmentForLaunchingPlugin(
                        pluginSocket: pluginSocket,
                        pluginIdentifier: pluginIdentifier
                    )
                )
            )
            controller.start()
            processControllers.append(controller)
        }
        
        let pluginsConnectionTimeout = 170.0
        Logger.debug("Waiting for all plugins to connect for \(pluginsConnectionTimeout) seconds")
        try eventDistributor.waitForPluginsToConnect(timeout: pluginsConnectionTimeout)
    }
    
    private func environmentForLaunchingPlugin(pluginSocket: String, pluginIdentifier: String) -> [String: String] {
        return [
            PluginSupport.pluginSocketEnv: pluginSocket,
            PluginSupport.pluginIdentifierEnv: pluginIdentifier
        ]
    }
    
    private func killPlugins() {
        Logger.debug("Killing plugins that are still alive")
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
        case .runnerEvent(let event):
            runnerEvent(event)
        case .tearDown:
            tearDown()
        }
    }
    
    private func runnerEvent(_ event: RunnerEvent) {}
    
    private func tearDown() {
        do {
            let tearDownAllowance: TimeInterval = 10.0
            Logger.debug("Waiting \(tearDownAllowance) seconds for plugins to tear down")
            try SynchronousWaiter.waitWhile(timeout: tearDownAllowance) {
                processControllers.map { $0.isProcessRunning }.contains(true)
            }
            Logger.debug("All plugins torn down successfully without force killing.")
        } catch {
            killPlugins()
        }
        eventDistributor.stop()
    }
    
    // MARK: - Re-distributing events to the plugins
    
    private func send(busEvent: BusEvent) {
        do {
            let data = try encoder.encode(busEvent)
            sendData(data)
        } catch {
            Logger.error("Failed to get data for \(busEvent) event: \(error)")
        }
    }
    
    private func sendData(_ data: Data) {
        eventDistributor.send(data: data)
    }
}
