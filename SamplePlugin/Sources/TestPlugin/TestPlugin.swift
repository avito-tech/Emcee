import EventBus
import Foundation
import Plugin

final class TestPlugin {
    private let eventBus: EventBus
    
    public init() {
        self.eventBus = TestPlugin.createEventBus(
            withAttachedListener: EventBusListener()
        )
    }
    
    public func run() throws {
        let plugin = try Plugin(eventBus: eventBus)
        plugin.streamPluginEvents()
        plugin.join()
    }
    
    private static func createEventBus(withAttachedListener listener: EventBusListener) -> EventBus {
        let eventBus = EventBus()
        eventBus.add(stream: listener)
        return eventBus
    }
}
