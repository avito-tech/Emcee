import EventBus
import Foundation
import Logging
import LoggingSetup
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
    
    override func process(event: BusEvent) {
        Logger.verboseDebug("Received bus event: \(event)")
        super.process(event: event)
    }
    
    override func didObtain(testingResult: TestingResult) {
        allEvents.append(testingResult)
    }
    
    override func tearDown() {
        write()
    }
    
    private func write() {
        do {
            Logger.debug("Writing output to: \(outputPath)")
            let encoder = JSONEncoder()
            let data = try encoder.encode(allEvents)
            try data.write(to: URL(fileURLWithPath: outputPath), options: .atomicWrite)
        } catch {
            Logger.error("Error: \(error)")
        }
    }
}

func main() throws -> Int32 {
    try LoggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
    
    guard let outputPath = ProcessInfo.processInfo.environment["AVITO_TEST_PLUGIN_OUTPUT"] else {
        Logger.fatal("TestingPlugin requires you to specify $AVITO_TEST_PLUGIN_OUTPUT")
    }
    Logger.debug("Started plugin")
    
    let eventBus = EventBus()
    let listener = Listener(outputPath: outputPath)
    eventBus.add(stream: listener)
    
    let plugin = try Plugin(eventBus: eventBus)
    plugin.streamPluginEvents()
    plugin.join()
    
    return 0
}

exit(try main())
