import EventBus
import Foundation
import Logging
import Models

final class EventBusListener: EventStream {
    private let outputPath: String
    private var busEvents = [BusEvent]()
    
    public init(outputPath: String) {
        self.outputPath = outputPath
    }
    
    func process(event: BusEvent) {
        log("Received event: \(event)")
        busEvents.append(event)
        if case BusEvent.tearDown = event {
            tearDown()
        }
    }
    
    func tearDown() {
        dump()
    }
    
    private func dump() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(busEvents)
            try data.write(to: URL(fileURLWithPath: outputPath))
        } catch {
            log("Error: \(error)", color: .red)
        }
    }
}
