import ArgLib
import DI
import DateProvider
import DeveloperDirLocator
import FileCache
import FileSystem
import Foundation
import LocalHostDeterminer
import Logging
import LoggingSetup
import Metrics
import PluginManager
import ProcessController
import QueueModels
import RequestSender
import ResourceLocationResolver
import TestDiscovery
import URLResource
import UniqueIdentifierGenerator

public final class InProcessMain {
    public init() {}
    
    public func run() throws {
        let di: DI = DIImpl()
       
        di.set(
            LocalFileSystem(),
            for: FileSystem.self
        )
        di.set(
            SystemDateProvider(),
            for: DateProvider.self
        )
        
        let cacheElementTimeToLive = TimeUnit.hours(1)
        let cacheMaximumSize = 20 * 1024 * 1024 * 1024
        let logsTimeToLive = TimeUnit.days(14)
        
        let logCleaningQueue = OperationQueue()
        try setupLogging(di: di, logsTimeToLive: logsTimeToLive, queue: logCleaningQueue)
        
        defer {
            tearDown(timeout: 10)
            logCleaningQueue.waitUntilAllOperationsAreFinished()
        }
        
        Logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")

        di.set(
            DefaultProcessControllerProvider(
                dateProvider: try di.get(),
                fileSystem: try di.get()
            ),
            for: ProcessControllerProvider.self
        )
        
        di.set(
            DefaultDeveloperDirLocator(
                processControllerProvider: try di.get()
            ),
            for: DeveloperDirLocator.self
        )
        
        di.set(
            DefaultRequestSenderProvider(),
            for: RequestSenderProvider.self
        )
        
        di.set(
            DefaultRuntimeDumpRemoteCacheProvider(
                senderProvider: try di.get()
            ),
            for: RuntimeDumpRemoteCacheProvider.self
        )
        
        di.set(
            ResourceLocationResolverImpl(
                fileSystem: try di.get(),
                urlResource: URLResource(
                    fileCache: try FileCache.fileCacheInDefaultLocation(
                        dateProvider: try di.get(),
                        fileSystem: try di.get()
                    ),
                    urlSession: URLSession.shared
                ),
                cacheElementTimeToLive: cacheElementTimeToLive.timeInterval,
                maximumCacheSize: cacheMaximumSize,
                processControllerProvider: try di.get()
            ),
            for: ResourceLocationResolver.self
        )
        
        di.set(
            PluginEventBusProviderImpl(
                processControllerProvider: try di.get(),
                resourceLocationResolver: try di.get()
            ),
            for: PluginEventBusProvider.self
        )
        
        di.set(
            UuidBasedUniqueIdentifierGenerator(),
            for: UniqueIdentifierGenerator.self
        )
        
        let commandInvoker = CommandInvoker(
            commands: [
                DistWorkCommand(di: di),
                DumpCommand(di: di),
                RunTestsOnRemoteQueueCommand(di: di),
                StartQueueServerCommand(di: di),
                try KickstartCommand(di: di),
                try EnableWorkerCommand(di: di),
                try DisableWorkerCommand(di: di),
                try ToggleWorkersSharingCommand(di: di),
                VersionCommand(),
            ],
            helpCommandType: .generateAutomatically
        )
        try commandInvoker.invokeSuitableCommand()
    }
    
    private func setupLogging(di: DI, logsTimeToLive: TimeUnit, queue: OperationQueue) throws {
        let loggingSetup = LoggingSetup(
            dateProvider: try di.get(),
            fileSystem: try di.get()
        )
        try loggingSetup.setupLogging(stderrVerbosity: Verbosity.info)
        try loggingSetup.cleanUpLogs(
            olderThan: try di.get(DateProvider.self).currentDate().addingTimeInterval(-logsTimeToLive.timeInterval),
            queue: queue,
            completion: { error in
                if let error = error {
                    Logger.error("Failed to clean up old logs: \(error)")
                } else {
                    Logger.info("Logs clean up complete")
                }
            }
        )
    }
    
    private func tearDown(timeout: TimeInterval) {
        LoggingSetup.tearDown(timeout: timeout)
        AnalyticsSetup.tearDown(timeout: timeout)
    }
}
