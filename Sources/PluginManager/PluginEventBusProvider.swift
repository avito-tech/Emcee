import EventBus
import FileSystem
import Foundation
import PluginSupport

public protocol PluginEventBusProvider {
    func createEventBus(
        fileSystem: FileSystem,
        pluginLocations: Set<AppleTestPluginLocation>
    ) throws -> EventBus
}
