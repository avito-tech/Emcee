import ArgLib
import DateProvider
import DeveloperDirLocator
import Extensions
import FileCache
import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import Metrics
import Models
import PluginManager
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

    private func runCommands() throws {
        let dateProvider = SystemDateProvider()
        let developerDirLocator = DefaultDeveloperDirLocator()
        let localQueueVersionProvider = FileHashVersionProvider(url: ProcessInfo.processInfo.executableUrl)
        let requestSenderProvider = DefaultRequestSenderProvider()
        let resourceLocationResolver = ResourceLocationResolverImpl(
            urlResource: URLResource(
                fileCache: try FileCache.fileCacheInDefaultLocation(),
                urlSession: URLSession.shared
            )
        )
        let pluginEventBusProvider: PluginEventBusProvider = PluginEventBusProviderImpl(
            resourceLocationResolver: resourceLocationResolver
        )
        
        let commandInvoker = CommandInvoker(
            commands: [
                DistWorkCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    pluginEventBusProvider: pluginEventBusProvider,
                    requestSenderProvider: requestSenderProvider,
                    resourceLocationResolver: resourceLocationResolver
                ),
                DumpRuntimeTestsCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    pluginEventBusProvider: pluginEventBusProvider,
                    resourceLocationResolver: resourceLocationResolver
                ),
                RunTestsOnRemoteQueueCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    localQueueVersionProvider: localQueueVersionProvider,
                    pluginEventBusProvider: pluginEventBusProvider,
                    requestSenderProvider: requestSenderProvider,
                    resourceLocationResolver: resourceLocationResolver
                ),
                StartQueueServerCommand(
                    localQueueVersionProvider: localQueueVersionProvider,
                    requestSenderProvider: requestSenderProvider,
                    requestSignature: RequestSignature(value: UUID().uuidString),
                    resourceLocationResolver: resourceLocationResolver
                ),
            ],
            helpCommandType: .generateAutomatically
        )
        try commandInvoker.invokeSuitableCommand()
    }
}
