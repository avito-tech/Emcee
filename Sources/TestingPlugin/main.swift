import DateProvider
import EventBus
import FileSystem
import Foundation
import Plugin

class Listener: DefaultBusListener {
    var allEvents = [RunnerEvent]()
    var allSignals = [UInt32]()
    
    override func runnerEvent(_ event: RunnerEvent) {
        allEvents.append(event)
    }
    
    override func tearDown() {
        write()
    }
    
    private func write() {
        for event in allEvents {
            do {
                guard let outputPath = event.testContext.environment["EMCEE_TEST_PLUGIN_OUTPUT"] else {
                    print("Error: TestingPlugin requires runner events to specify env.EMCEE_TEST_PLUGIN_OUTPUT")
                    exit(1)
                }
                let encoder = JSONEncoder()
                let data = try encoder.encode(event)
                try data.write(to: URL(fileURLWithPath: outputPath), options: .atomicWrite)
            } catch {
                print("Error: \(error)")
            }
        }
    }
}

func main() throws -> Int32 {
    let eventBus = EventBus()
    let listener = Listener()
    eventBus.add(stream: listener)
    
    let plugin = try Plugin(eventBus: eventBus)
    plugin.streamPluginEvents()
    plugin.join()
    
    return 0
}

exit(try main())
