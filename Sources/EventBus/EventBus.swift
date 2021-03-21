import Dispatch
import Extensions
import Foundation

public final class EventBus {
    private var streams = [EventStream]()
    private let lock = NSLock()
    private let eventDeliveryQueue = DispatchQueue(label: "ru.avito.EventBus.eventDeliveryQueue")
    
    public init() {}
    
    public func add(stream: EventStream) {
        lock.whileLocked {
            streams.append(stream)
        }
    }
    
    public func post(event: BusEvent) {
        lock.whileLocked {
            streams.forEach { stream in
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
        eventDeliveryQueue.sync(flags: .barrier) {}
    }
}
