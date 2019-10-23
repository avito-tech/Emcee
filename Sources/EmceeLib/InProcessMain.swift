import ArgLib
import DeveloperDirLocator
import Extensions
import FileCache
import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import Metrics
import Models
import ProcessController
import RequestSender
import ResourceLocationResolver
import URLResource
import Version

public final class InProcessMain {
    public init() {}
    
    public func run() throws {
        try! LoggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
        defer { LoggingSetup.tearDown() }
        
        Logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")
        
        try runCommands()
    }
    
    private static func cacheContainerUrl() throws -> URL {
        let cacheContainer = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return cacheContainer.appendingPathComponent("ru.avito.Runner.cache", isDirectory: true)
    }

    private func runCommands() throws {
        let developerDirLocator = DefaultDeveloperDirLocator()
        let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
        let requestSenderProvider = DefaultRequestSenderProvider()
        let resourceLocationResolver = ResourceLocationResolverImpl(
            urlResource: URLResource(
                fileCache: try FileCache(cachesUrl: try InProcessMain.cacheContainerUrl()),
                urlSession: URLSession.shared
            )
        )
        
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
