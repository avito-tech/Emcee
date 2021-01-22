import EventBus
import Foundation
import JSONStream
import Logging

final class JSONStreamToEventBusAdapter: JSONReaderEventStream {
    private let eventBus: EventBus
    private let decoder = JSONDecoder()
    
    public init(eventBus: EventBus) {
        self.eventBus = eventBus
    }
    
    func newArray(_ array: NSArray, data: Data) {
        Logger.error("JSON stream reader received an unexpected event: '\(data)'")
    }
    
    func newObject(_ object: NSDictionary, data: Data) {
        do {
            let busEvent = try decoder.decode(BusEvent.self, from: data)
            eventBus.post(event: busEvent)
        } catch {
            Logger.error("Failed to decode plugin event: \(error)")
            let string = String(data: data, encoding: .utf8)
            Logger.debug("JSON String: \(String(describing: string))")
        }
    }
}
