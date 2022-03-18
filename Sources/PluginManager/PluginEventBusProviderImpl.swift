import EmceeLogging
import EventBus
import FileSystem
import Foundation
import PluginSupport
import ProcessController
import ResourceLocationResolver
import HostnameProvider

public final class PluginEventBusProviderImpl: PluginEventBusProvider {
    private let logger: ContextualLogger
    private let hostnameProvider: HostnameProvider
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        logger: ContextualLogger,
        hostnameProvider: HostnameProvider,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.logger = logger
        self.hostnameProvider = hostnameProvider
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func createEventBus(
        fileSystem: FileSystem,
        pluginLocations: Set<AppleTestPluginLocation>
    ) throws -> EventBus {
        let eventBus = EventBus()
        try startPluginManager(
            fileSystem: fileSystem,
            eventBus: eventBus,
            pluginLocations: pluginLocations
        )
        return eventBus
    }
    
    private func startPluginManager(
        fileSystem: FileSystem,
        eventBus: EventBus,
        pluginLocations: Set<AppleTestPluginLocation>
    ) throws {
        let pluginManager = PluginManager(
            fileSystem: fileSystem,
            logger: logger,
            hostname: hostnameProvider.hostname,
            pluginLocations: pluginLocations,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver
        )
        try pluginManager.startPlugins()
        eventBus.add(stream: pluginManager)
    }
}
