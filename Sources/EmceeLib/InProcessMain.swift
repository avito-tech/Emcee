import Extensions
import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import Metrics
import ProcessController

public final class InProcessMain {
    public init() {}
    
    public func run() throws {
        try! LoggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
        defer { LoggingSetup.tearDown() }
        
        Logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")
        
        var registry = SPMCommandRegistry(
            usage: "<subcommand> <options>",
            overview: "Runs specific tasks related to iOS UI testing"
        )
        
        registry.register(command: DistWorkCommand.self)
        registry.register(command: DumpRuntimeTestsCommand.self)
        registry.register(command: RunTestsCommand.self)
        registry.register(command: RunTestsOnRemoteQueueCommand.self)
        registry.register(command: StartQueueServerCommand.self)
        
        try registry.run()
    }
}
