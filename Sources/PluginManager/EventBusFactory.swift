import EventBus
import Foundation
import Models

public final class EventBusFactory {
    private init() {}
    
    public static func createEventBusWithAttachedPluginManager(
        pluginLocations: [ResourceLocation],
        environment: [String : String]
        ) throws -> EventBus
    {
        let eventBus = EventBus()
        try startPluginManager(eventBus: eventBus, pluginLocations: pluginLocations, environment: environment)
        return eventBus
    }
    
    private static func startPluginManager(
        eventBus: EventBus,
        pluginLocations: [ResourceLocation],
        environment: [String : String]) throws
    {
        let pluginManager = try PluginManager(
            pluginLocations: pluginLocations,
            environment: environment)
        try pluginManager.startPlugins()
        eventBus.add(stream: pluginManager)
    }
}
