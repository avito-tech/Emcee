import ArgLib
import DI
import DateProvider
import DeveloperDirLocator
import EmceeLogging
import FileCache
import FileSystem
import Foundation
import LocalHostDeterminer
import LoggingSetup
import Logging
import Metrics
import MetricsExtensions
import PathLib
import PluginManager
import ProcessController
import QueueModels
import RequestSender
import ResourceLocationResolver
import Runner
import SynchronousWaiter
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
        di.set(
            SpecificMetricRecorderProviderImpl(
                mutableMetricRecorderProvider: MutableMetricRecorderProviderImpl(
                    queue: DispatchQueue(
                        label: "MutableMetricRecorderProvider.queue",
                        attributes: .concurrent,
                        target: .global()
                    )
                )
            ),
            for: SpecificMetricRecorderProvider.self
        )
        
        // global metric recorder to be configured after obtaining analytics configuration 
        di.set(
            GlobalMetricRecorderImpl(),
            for: GlobalMetricRecorder.self
        )
        
        let globalMmetricRecorder: GlobalMetricRecorder = try di.get()
        let specificMetricRecorderProvider: SpecificMetricRecorderProvider = try di.get()
        
        let cacheElementTimeToLive = TimeUnit.hours(1)
        let cacheMaximumSize = 20 * 1024 * 1024 * 1024
        let logsTimeToLive = TimeUnit.days(14)
        
        let logCleaningQueue = OperationQueue()
        di.set(
            LoggingSetup(
                dateProvider: try di.get(),
                fileSystem: try di.get()
            )
        )
        
        let logger = try setupLogging(di: di, logsTimeToLive: logsTimeToLive, queue: logCleaningQueue)
        
        defer {
            let timeout: TimeInterval = 10
            LoggingSetup.tearDown(timeout: timeout)
            specificMetricRecorderProvider.tearDown(timeout: timeout)
            globalMmetricRecorder.tearDown(timeout: timeout)
            logCleaningQueue.waitUntilAllOperationsAreFinished()
        }
        
        logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")

        di.set(
            try DetailedAcitivityLoggableProcessControllerProvider(di: di),
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
            try FileCache.fileCacheInDefaultLocation(
                dateProvider: try di.get(),
                fileSystem: try di.get()
            ),
            for: FileCache.self
        )
        
        di.set(
            URLResourceImpl(
                fileCache: try di.get(),
                urlSession: URLSession.shared
            ),
            for: URLResource.self
        )
        
        di.set(
            ResourceLocationResolverImpl(
                fileSystem: try di.get(),
                urlResource: try di.get(),
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
        
        di.set(
            DefaultTestRunnerProvider(
                dateProvider: try di.get(),
                processControllerProvider: try di.get(),
                resourceLocationResolver: try di.get()
            ),
            for: TestRunnerProvider.self
        )
        
        di.set(
            SynchronousWaiter(),
            for: Waiter.self
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
    
    private func setupLogging(di: DI, logsTimeToLive: TimeUnit, queue: OperationQueue) throws -> ContextualLogger {
        let loggingSetup: LoggingSetup = try di.get()
        try loggingSetup.setupLogging(stderrVerbosity: .info)
        
        let logger = ContextualLogger(InProcessMain.self)
        
        try loggingSetup.cleanUpLogs(
            olderThan: try di.get(DateProvider.self).currentDate().addingTimeInterval(-logsTimeToLive.timeInterval),
            queue: queue,
            completion: { error in
                if let error = error {
                    logger.error("Failed to clean up old logs: \(error)")
                }
            }
        )
        
        return logger
    }
}
