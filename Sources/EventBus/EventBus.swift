import Dispatch
import Foundation
import Models

public final class EventBus {
    private var streams = [EventStream]()
    private let workQueue = DispatchQueue(label: "ru.avito.EventBus.workQueue")
    
    public init() {}
    
    public func add(stream: EventStream) {
        workQueue.async {
            self.streams.append(stream)
        }
    }
    
    public func post(event: BusEvent) {
        forEachStream { stream in
            stream.process(event: event)
        }
    }
    
    public func waitForDeliveryOfAllPendingEvents() {
        workQueue.sync {}
    }
    
    public func uponDeliveryOfAllEvents(work: @escaping () -> ()) {
        workQueue.async {
            work()
        }
    }
    
    public func tearDown() {
        post(event: .tearDown)
        waitForDeliveryOfAllPendingEvents()
    }
    
    private func forEachStream(work: @escaping (EventStream) -> ()) {
        workQueue.async {
            for stream in self.streams {
                work(stream)
            }
        }
    }
}
