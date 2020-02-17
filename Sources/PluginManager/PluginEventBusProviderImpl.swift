import EventBus
import Foundation
import ResourceLocationResolver
import PluginSupport

public final class PluginEventBusProviderImpl: PluginEventBusProvider {
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func createEventBus(
        pluginLocations: Set<PluginLocation>
    ) throws -> EventBus {
        let eventBus = EventBus()
        try startPluginManager(
            eventBus: eventBus,
            pluginLocations: pluginLocations
        )
        return eventBus
    }
    
    private func startPluginManager(
        eventBus: EventBus,
        pluginLocations: Set<PluginLocation>
    ) throws {
        let pluginManager = PluginManager(
            pluginLocations: pluginLocations,
            resourceLocationResolver: resourceLocationResolver
        )
        try pluginManager.startPlugins()
        eventBus.add(stream: pluginManager)
    }
}
