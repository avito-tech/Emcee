import ArgLib
import DateProvider
import DeveloperDirLocator
import Extensions
import FileCache
import FileSystem
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
import TestDiscovery
import URLResource
import UniqueIdentifierGenerator

public final class InProcessMain {
    public init() {}
    
    public func run() throws {
        let fileSystem = LocalFileSystem()
        let dateProvider = SystemDateProvider()
        
        let cacheElementTimeToLive = TimeUnit.hours(1)
        let logsTimeToLive = TimeUnit.days(30)
        
        let loggingSetup = LoggingSetup(
            fileSystem: fileSystem
        )
        try loggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
        try loggingSetup.cleanUpLogs(olderThan: dateProvider.currentDate().addingTimeInterval(-logsTimeToLive.timeInterval))
        
        defer {
            loggingSetup.tearDown(timeout: 10)
            AnalyticsSetup.tearDown(timeout: 10)
        }
        
        Logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")
        
        let processControllerProvider = DefaultProcessControllerProvider(
            dateProvider: dateProvider,
            fileSystem: fileSystem
        )
        let developerDirLocator = DefaultDeveloperDirLocator(
            processControllerProvider: processControllerProvider
        )
        let requestSenderProvider = DefaultRequestSenderProvider()
        let runtimeDumpRemoteCacheProvider = DefaultRuntimeDumpRemoteCacheProvider(senderProvider: requestSenderProvider)
        let resourceLocationResolver = ResourceLocationResolverImpl(
            fileSystem: fileSystem,
            urlResource: URLResource(
                fileCache: try FileCache.fileCacheInDefaultLocation(
                    fileSystem: fileSystem
                ),
                urlSession: URLSession.shared
            ),
            cacheElementTimeToLive: cacheElementTimeToLive.timeInterval,
            processControllerProvider: processControllerProvider
        )
        let pluginEventBusProvider: PluginEventBusProvider = PluginEventBusProviderImpl(
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver
        )
        let uniqueIdentifierGenerator = UuidBasedUniqueIdentifierGenerator()
        
        let commandInvoker = CommandInvoker(
            commands: [
                DistWorkCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    fileSystem: fileSystem,
                    pluginEventBusProvider: pluginEventBusProvider,
                    processControllerProvider: processControllerProvider,
                    requestSenderProvider: requestSenderProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator
                ),
                DumpCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    fileSystem: fileSystem,
                    pluginEventBusProvider: pluginEventBusProvider,
                    processControllerProvider: processControllerProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator,
                    runtimeDumpRemoteCacheProvider: runtimeDumpRemoteCacheProvider
                ),
                RunTestsOnRemoteQueueCommand(
                    dateProvider: dateProvider,
                    developerDirLocator: developerDirLocator,
                    fileSystem: fileSystem,
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
                    processControllerProvider: processControllerProvider,
                    resourceLocationResolver: resourceLocationResolver,
                    uniqueIdentifierGenerator: uniqueIdentifierGenerator
                ),
                EnableWorkerCommand(
                    requestSenderProvider: requestSenderProvider
                ),
                DisableWorkerCommand(
                    requestSenderProvider: requestSenderProvider
                ),
                ToggleWorkersSharingCommand(
                    requestSenderProvider: requestSenderProvider
                ),
            ],
            helpCommandType: .generateAutomatically
        )
        try commandInvoker.invokeSuitableCommand()
    }
}
