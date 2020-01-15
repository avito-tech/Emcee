import Foundation

public final class BlockBasedEventStream: EventStream {
    private let onEvent: (BusEvent) -> ()
    
    public init(onEvent: @escaping (BusEvent) -> ()) {
        self.onEvent = onEvent
    }
    
    public func process(event: BusEvent) {
        onEvent(event)
    }
}
