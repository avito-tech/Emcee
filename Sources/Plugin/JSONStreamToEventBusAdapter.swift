import EmceeLogging
import EventBus
import Foundation
import JSONStream

final class JSONStreamToEventBusAdapter: JSONReaderEventStream {
    private let eventBus: EventBus
    private let logger: ContextualLogger
    private let decoder = JSONDecoder()
    
    public init(
        eventBus: EventBus,
        logger: ContextualLogger
    ) {
        self.eventBus = eventBus
        self.logger = logger.forType(Self.self)
    }
    
    func newArray(_ array: NSArray, data: Data) {
        logger.warning("JSON stream reader received an unexpected event: '\(data)'")
    }
    
    func newObject(_ object: NSDictionary, data: Data) {
        do {
            let busEvent = try decoder.decode(BusEvent.self, from: data)
            eventBus.post(event: busEvent)
        } catch {
            let string = String(data: data, encoding: .utf8)
            logger.error("Failed to decode plugin event: \(error). JSON string: \(String(describing: string))")
        }
    }
}
