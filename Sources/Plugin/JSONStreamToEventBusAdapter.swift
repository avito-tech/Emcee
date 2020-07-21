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
    
    func newArray(_ array: NSArray, scalars: [Unicode.Scalar]) {
        Logger.error("JSON stream reader received an unexpected event: '\(scalars)'")
    }
    
    func newObject(_ object: NSDictionary, scalars: [Unicode.Scalar]) {
        var string = String()
        string.unicodeScalars.append(contentsOf: scalars)
        guard let eventData = string.data(using: .utf8) else {
            Logger.warning("Failed to convert JSON string to data: '\(string)'")
            return
        }
        
        do {
            let busEvent = try decoder.decode(BusEvent.self, from: eventData)
            eventBus.post(event: busEvent)
        } catch {
            Logger.error("Failed to decode plugin event: \(error)")
            Logger.debug("JSON String: \(string)")
        }
    }
}
