import EmceeLogging
import EventBus
import FileSystem
import Foundation
import PluginSupport
import ProcessController
import ResourceLocationResolver

public final class PluginEventBusProviderImpl: PluginEventBusProvider {
    private let logger: ContextualLogger
    private let processControllerProvider: ProcessControllerProvider
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(
        logger: ContextualLogger,
        processControllerProvider: ProcessControllerProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.logger = logger.forType(Self.self)
        self.processControllerProvider = processControllerProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func createEventBus(
        fileSystem: FileSystem,
        pluginLocations: Set<PluginLocation>
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
        pluginLocations: Set<PluginLocation>
    ) throws {
        let pluginManager = PluginManager(
            fileSystem: fileSystem,
            logger: logger,
            pluginLocations: pluginLocations,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver
        )
        try pluginManager.startPlugins()
        eventBus.add(stream: pluginManager)
    }
}
