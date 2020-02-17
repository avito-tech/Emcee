import EventBus
import Foundation
import PluginSupport

public protocol PluginEventBusProvider {
    func createEventBus(
        pluginLocations: Set<PluginLocation>
    ) throws -> EventBus
}
