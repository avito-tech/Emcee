import EventBus
import Extensions
import FileSystem
import Foundation
import Logging
import Models
import PathLib
import PluginSupport
import ProcessController
import ResourceLocationResolver
import SynchronousWaiter

public final class PluginManager: EventStream {
    private let encoder = JSONEncoder.pretty()
    private let eventDistributor: EventDistributor
    private let fileSystem: FileSystem
    private let pluginLocations: Set<PluginLocation>
    private let pluginsConnectionTimeout: TimeInterval = 30.0
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let sessionId = UUID()
    private let tearDownAllowance: TimeInterval = 60.0
    private var processControllers = [ProcessController]()
    
    public static let pluginBundleExtension = "emceeplugin"
    public static let pluginExecutableName = "Plugin"
    
    public init(
        fileSystem: FileSystem,
        pluginLocations: Set<PluginLocation>,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.fileSystem = fileSystem
        self.eventDistributor = EventDistributor(sessionId: sessionId)
        self.pluginLocations = pluginLocations
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    private func pathsToPluginBundles() throws -> [AbsolutePath] {
        var paths = [AbsolutePath]()
        for location in pluginLocations {
            let resolvableLocation = resourceLocationResolver.resolvable(withRepresentable: location)
            
            let validatePathToPluginBundle: (AbsolutePath) throws -> () = { path in
                guard path.lastComponent.pathExtension == PluginManager.pluginBundleExtension else {
                    throw ValidationError.unexpectedExtension(location, actual: path.lastComponent.pathExtension, expected: PluginManager.pluginBundleExtension)
                }
                let executablePath = path.appending(component: PluginManager.pluginExecutableName)
                
                guard try self.fileSystem.properties(forFileAtPath: executablePath).isExecutable() else {
                    throw ValidationError.noExecutableFound(location, expectedLocation: executablePath)
                }
                
                paths.append(path)
            }
            
            switch try resolvableLocation.resolve() {
            case .directlyAccessibleFile(let path):
                try validatePathToPluginBundle(path)
            case .contentsOfArchive(let containerPath, let concretePluginName):
                if let concretePluginName = concretePluginName {
                    var path = containerPath.appending(component: concretePluginName)
                    if path.lastComponent.pathExtension != PluginManager.pluginBundleExtension {
                        path = path.appending(extension: PluginManager.pluginBundleExtension)
                    }
                    try validatePathToPluginBundle(path)
                } else {
                    var availablePlugins = [AbsolutePath]()
                    try fileSystem.contentEnumerator(forPath: containerPath, style: .shallow).each { path in
                        if path.extension == PluginManager.pluginBundleExtension {
                            availablePlugins.append(path)
                        }
                    }
                    
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
        
        let pluginBundles = try pathsToPluginBundles()
        
        for bundlePath in pluginBundles {
            Logger.debug("[\(sessionId)] Starting plugin at '\(bundlePath)'")
            let pluginExecutable = bundlePath.appending(component: PluginManager.pluginExecutableName)
            let pluginIdentifier = try pluginExecutable.pathString.avito_sha256Hash()
            eventDistributor.add(pluginIdentifier: pluginIdentifier)
            let controller = try processControllerProvider.createProcessController(
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
        
        do {
            try eventDistributor.waitForPluginsToConnect(timeout: pluginsConnectionTimeout)
        } catch {
            Logger.error("[\(sessionId)] Failed to start plugins, will not tear down")
            tearDown()
            throw error
        }
    }
    
    private func environmentForLaunchingPlugin(pluginSocket: String, pluginIdentifier: String) -> [String: String] {
        return [
            PluginSupport.pluginSocketEnv: pluginSocket,
            PluginSupport.pluginIdentifierEnv: pluginIdentifier
        ]
    }
    
    private func killPlugins() {
        Logger.debug("[\(sessionId)] Killing plugins that are still alive")
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
            try SynchronousWaiter().waitWhile(timeout: tearDownAllowance, description: "[\(sessionId)] Tear down plugins") {
                processControllers.map { $0.isProcessRunning }.contains(true)
            }
            Logger.debug("[\(sessionId)] All plugins torn down successfully without force killing.")
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
            Logger.error("[\(sessionId)] Failed to get data for \(busEvent) event: \(error)")
        }
    }
    
    private func sendData(_ data: Data) {
        eventDistributor.send(data: data)
    }
}
