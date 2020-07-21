import DateProvider
import EventBus
import FileSystem
import Foundation
import Logging
import LoggingSetup
import Plugin

class Listener: DefaultBusListener {
    var allEvents = [RunnerEvent]()
    var allSignals = [UInt32]()
    
    override func process(event: BusEvent) {
        Logger.verboseDebug("Received bus event: \(event)")
        super.process(event: event)
    }
    
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
                    Logger.fatal("TestingPlugin requires runner events to specify env.EMCEE_TEST_PLUGIN_OUTPUT")
                }
                Logger.debug("Writing event \(event) to: \(outputPath)")
                let encoder = JSONEncoder()
                let data = try encoder.encode(event)
                try data.write(to: URL(fileURLWithPath: outputPath), options: .atomicWrite)
            } catch {
                Logger.error("Error: \(error)")
            }
        }
    }
}

func main() throws -> Int32 {
    let loggingSetup = LoggingSetup(
        dateProvider: SystemDateProvider(),
        fileSystem: LocalFileSystem()
    )
    
    try loggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
    defer {
        loggingSetup.tearDown(timeout: 10)
    }

    Logger.debug("Started plugin")
    
    let eventBus = EventBus()
    let listener = Listener()
    eventBus.add(stream: listener)
    
    let plugin = try Plugin(eventBus: eventBus)
    plugin.streamPluginEvents()
    plugin.join()
    
    return 0
}

exit(try main())
