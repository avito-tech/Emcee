import EventBus
import FileSystem
import Foundation
import PluginManager
import PluginSupport

public final class NoOoPluginEventBusProvider: PluginEventBusProvider {
    public init() {}
    
    public var eventBus = EventBus()
    public var eventBusRequests = 0
    
    public func createEventBus(fileSystem: FileSystem, pluginLocations: Set<AppleTestPluginLocation>) throws -> EventBus {
        eventBusRequests += 1
        return eventBus
    }
}
