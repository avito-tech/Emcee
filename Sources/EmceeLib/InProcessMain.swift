import ArgLib
import DeveloperDirLocator
import Extensions
import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import Metrics
import Models
import ProcessController
import RequestSender
import ResourceLocationResolver
import Version

public final class InProcessMain {
    public init() {}
    
    public func run() throws {
        try! LoggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
        defer { LoggingSetup.tearDown() }
        
        Logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")
        
        try runCommands()
    }

    private func runCommands() throws {
        let developerDirLocator = DefaultDeveloperDirLocator()
        let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
        let requestSenderProvider = DefaultRequestSenderProvider()
        let resourceLocationResolver = try ResourceLocationResolver()
        
        let commandInvoker = CommandInvoker(
            commands: [
                DistWorkCommand(
                    developerDirLocator: developerDirLocator,
                    requestSenderProvider: requestSenderProvider,
                    resourceLocationResolver: resourceLocationResolver
                ),
                DumpRuntimeTestsCommand(
                    developerDirLocator: developerDirLocator,
                    resourceLocationResolver: resourceLocationResolver
                ),
                RunTestsOnRemoteQueueCommand(
                    developerDirLocator: developerDirLocator,
                    localQueueVersionProvider: localQueueVersionProvider,
                    requestSenderProvider: requestSenderProvider,
                    resourceLocationResolver: resourceLocationResolver
                ),
                StartQueueServerCommand(
                    localQueueVersionProvider: localQueueVersionProvider,
                    requestSenderProvider: requestSenderProvider,
                    requestSignature: RequestSignature(value: UUID().uuidString),
                    resourceLocationResolver: resourceLocationResolver
                ),
            ]
        )
        try commandInvoker.invokeSuitableCommand()
    }
}
