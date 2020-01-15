import EventBus
import Foundation
import Models

public protocol PluginEventBusProvider {
    func createEventBus(
        pluginLocations: Set<PluginLocation>
    ) throws -> EventBus
}
