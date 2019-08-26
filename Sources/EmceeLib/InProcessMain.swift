import ArgLib
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
        
        try runCommands()
    }

    private func runCommands() throws {
        let commandInvoker = CommandInvoker(
            commands: [
                DistWorkCommand(),
                DumpRuntimeTestsCommand(),
                RunTestsOnRemoteQueueCommand(),
                StartQueueServerCommand(),
            ]
        )
        try commandInvoker.invokeSuitableCommand()
    }
}
