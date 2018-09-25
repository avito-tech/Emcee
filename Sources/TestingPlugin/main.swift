import EventBus
import Foundation
import Logging
import Models
import Plugin

class Listener: DefaultBusListener {
    var allEvents = [TestingResult]()
    var allSignals = [UInt32]()
    let outputPath: String
    
    public init(outputPath: String) {
        self.outputPath = outputPath
        super.init()
    }
    
    override func didObtain(testingResult: TestingResult) {
        allEvents.append(testingResult)
    }
    
    override func tearDown() {
        write()
    }
    
    private func write() {
        do {
            log("Writing output to: \(outputPath)")
            let encoder = JSONEncoder()
            let data = try encoder.encode(allEvents)
            try data.write(to: URL(fileURLWithPath: outputPath), options: .atomicWrite)
        } catch {
            log("Error: \(error)")
        }
    }
}

func main() -> Int32 {
    guard let outputPath = ProcessInfo.processInfo.environment["AVITO_TEST_PLUGIN_OUTPUT"] else {
        log("TestingPlugin requires you to specify $AVITO_TEST_PLUGIN_OUTPUT")
        return 1
    }
    log("Started plugin")
    
    let eventBus = EventBus()
    let listener = Listener(outputPath: outputPath)
    eventBus.add(stream: listener)
    
    let plugin = Plugin(eventBus: eventBus)
    plugin.streamPluginEvents()
    plugin.join()
    
    return 0
}

exit(main())
