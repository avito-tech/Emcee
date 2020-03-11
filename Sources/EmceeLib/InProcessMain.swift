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
import RuntimeDump
import URLResource
import UniqueIdentifierGenerator

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
        let requestSenderProvider = DefaultRequestSenderProvider()
        let runtimeDumpRemoteCacheProvider = DefaultRuntimeDumpRemoteCacheProvider(senderProvider: requestSenderProvider)
        let resourceLocationResolver = ResourceLocationResolverImpl(
            urlResource: URLResource(
                fileCache: try FileCache.fileCacheInDefaultLocation(),
                urlSession: URLSession.shared
            )
        )
        let pluginEventBusProvider: PluginEventBusProvider = PluginEventBusProviderImpl(
            resourceLocationResolver: resourceLocationResolver
        )
        let processControllerProvider = DefaultProcessControllerProvider()
        let uniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
        
        let commandInvoker = CommandInvoker(
            commands: [
                DistWorkCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    pluginEventBusProvider: pluginEventBusProvider,
                    processControllerProvider: processControllerProvider,
                    requestSenderProvider: requestSenderProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator
                ),
                DumpRuntimeTestsCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    pluginEventBusProvider: pluginEventBusProvider,
                    processControllerProvider: processControllerProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator,
                    runtimeDumpRemoteCacheProvider: runtimeDumpRemoteCacheProvider
                ),
                RunTestsOnRemoteQueueCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    pluginEventBusProvider: pluginEventBusProvider,
                    processControllerProvider: processControllerProvider,
                    requestSenderProvider: requestSenderProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator,
                    runtimeDumpRemoteCacheProvider: runtimeDumpRemoteCacheProvider
                ),
                StartQueueServerCommand(
                    requestSenderProvider: requestSenderProvider,
                    payloadSignature: PayloadSignature(value: UUID().uuidString),
                    resourceLocationResolver: resourceLocationResolver,
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator
                ),
            ],
            helpCommandType: .generateAutomatically
        )
        try commandInvoker.invokeSuitableCommand()
    }
}
