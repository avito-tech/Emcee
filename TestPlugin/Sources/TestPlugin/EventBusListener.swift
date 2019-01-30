import EventBus
import Foundation
import Logging
import Models

final class EventBusListener: EventStream {
    private let outputPath: String
    private var busEvents = [BusEvent]()
    
    public init() {
        outputPath = ProcessInfo.processInfo.arguments[0].deletingLastPathComponent.appending(pathComponent: "output.json")
    }
    
    func process(event: BusEvent) {
        Logger.debug("Received event: \(event)")
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
            try FileManager.default.createDirectory(
                atPath: (outputPath as NSString).deletingLastPathComponent,
                withIntermediateDirectories: true
            )
            if FileManager.default.fileExists(atPath: outputPath) {
                try FileManager.default.removeItem(atPath: outputPath)
            }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(busEvents)
            try data.write(to: URL(fileURLWithPath: outputPath))
            Logger.info("Dumped \(busEvents.count) events to file: '\(outputPath)'")
        } catch {
            Logger.error("\(error)")
        }
    }
}
