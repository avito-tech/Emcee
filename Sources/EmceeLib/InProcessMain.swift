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
        // TODO: remove SPM branch when all commands are migrated to ArgLib
        do {
            try runArgLibCommands()
        } catch {
            if let commandParserError = error as? CommandParserError {
                switch commandParserError {
                case .unknownCommand:
                    try runSPMCommands()
                default:
                    throw error
                }
            } else {
                throw error
            }
        }
    }
    
    private func runArgLibCommands() throws {
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
    
    private func runSPMCommands() throws {
        var registry = SPMCommandRegistry(
            usage: "<subcommand> <options>",
            overview: "Runs specific tasks related to iOS UI testing"
        )
        
        registry.register(command: RunTestsCommand.self)
        
        try registry.run()
    }
}
