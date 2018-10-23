import EventBus
import Foundation
import Models

public final class EventBusFactory {
    private init() {}
    
    public static func createEventBusWithAttachedPluginManager(
        pluginLocations: [ResolvableResourceLocation],
        environment: [String : String]
        ) throws -> EventBus
    {
        let eventBus = EventBus()
        try startPluginManager(eventBus: eventBus, pluginLocations: pluginLocations, environment: environment)
        return eventBus
    }
    
    private static func startPluginManager(
        eventBus: EventBus,
        pluginLocations: [ResolvableResourceLocation],
        environment: [String : String]) throws
    {
        let pluginManager = PluginManager(
            pluginLocations: pluginLocations,
            environment: environment)
        try pluginManager.startPlugins()
        eventBus.add(stream: pluginManager)
    }
}
