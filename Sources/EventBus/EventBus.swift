import Dispatch
import Foundation
import Logging

public final class EventBus {
    private var streams = [EventStream]()
    private let workQueue = DispatchQueue(label: "ru.avito.EventBus.workQueue")
    private let eventDeliveryQueue = DispatchQueue(label: "ru.avito.EventBus.eventDeliveryQueue")
    
    public init() {}
    
    public func add(stream: EventStream) {
        workQueue.sync {
            streams.append(stream)
        }
    }
    
    public func post(event: BusEvent) {
        workQueue.sync {
            streams.forEach { stream in
                Logger.verboseDebug("Posting event to stream \(stream): \(event)")
                eventDeliveryQueue.async {
                    stream.process(event: event)
                }
            }
        }
    }
    
    public func uponDeliveryOfAllEvents(work: @escaping () -> ()) {
        eventDeliveryQueue.async {
            work()
        }
    }
    
    public func tearDown() {
        post(event: .tearDown)
        eventDeliveryQueue.sync {}
    }
}
