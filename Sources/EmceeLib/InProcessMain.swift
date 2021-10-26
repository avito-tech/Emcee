import AppleTools
import ArgLib
import DI
import DateProvider
import DeveloperDirLocator
import EmceeLogging
import EmceeVersion
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
        
        let globalMetricRecorder: GlobalMetricRecorder = try di.get()
        let specificMetricRecorderProvider: SpecificMetricRecorderProvider = try di.get()
        
        let cacheElementTimeToLive = TimeUnit.hours(1)
        let cacheMaximumSize = 10 * 1024 * 1024 * 1024
        let logsTimeToLive = TimeUnit.days(5)
        
        let logCleaningQueue = OperationQueue()
        di.set(
            LoggingSetup(
                dateProvider: try di.get(),
                fileSystem: try di.get()
            )
        )
        
        let logger = try setupLogging(di: di, logsTimeToLive: logsTimeToLive, queue: logCleaningQueue)
            .withMetadata(key: .hostname, value: LocalHostDeterminer.currentHostAddress)
            .withMetadata(key: .emceeVersion, value: EmceeVersion.version.value)
            .withMetadata(key: .processId, value: "\(ProcessInfo.processInfo.processIdentifier)")
            .withMetadata(key: .processName, value: ProcessInfo.processInfo.processName)
        di.set(logger)
        
        defer {
            let timeout: TimeInterval = 10
            LoggingSetup.tearDown(timeout: timeout)
            specificMetricRecorderProvider.tearDown(timeout: timeout)
            globalMetricRecorder.tearDown(timeout: timeout)
            logCleaningQueue.waitUntilAllOperationsAreFinished()
        }
        
        logger.info("Arguments: \(ProcessInfo.processInfo.arguments)")

        di.set(
            try DetailedActivityLoggableProcessControllerProvider(di: di),
            for: ProcessControllerProvider.self
        )
        
        di.set(
            DefaultDeveloperDirLocator(
                processControllerProvider: try di.get()
            ),
            for: DeveloperDirLocator.self
        )
        
        di.set(
            DefaultRequestSenderProvider(
                logger: logger
            ),
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
                logger: logger,
                urlSession: URLSession.shared
            ),
            for: URLResource.self
        )
        
        di.set(
            ResourceLocationResolverImpl(
                fileSystem: try di.get(),
                logger: logger,
                urlResource: try di.get(),
                cacheElementTimeToLive: cacheElementTimeToLive.timeInterval,
                maximumCacheSize: cacheMaximumSize,
                processControllerProvider: try di.get()
            ),
            for: ResourceLocationResolver.self
        )
        
        di.set(
            RunnerWasteCollectorProviderImpl(),
            for: RunnerWasteCollectorProvider.self
        )
        
        di.set(
            PluginEventBusProviderImpl(
                logger: logger,
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
            XcResultToolImpl(
                dateProvider: try di.get(),
                logger: logger,
                processControllerProvider: try di.get()
            ),
            for: XcResultTool.self
        )
        
        di.set(
            DefaultTestRunnerProvider(
                dateProvider: try di.get(),
                fileSystem: try di.get(),
                processControllerProvider: try di.get(),
                resourceLocationResolver: try di.get(),
                xcResultTool: try di.get()
            ),
            for: TestRunnerProvider.self
        )
        
        di.set(
            SynchronousWaiter(),
            for: Waiter.self
        )
        
        let commandInvoker = CommandInvoker(
            commands: [
                try DistWorkCommand(di: di),
                try DumpCommand(di: di),
                try RunTestsOnRemoteQueueCommand(di: di),
                try StartQueueServerCommand(di: di),
                try KickstartCommand(di: di),
                try EnableWorkerCommand(di: di),
                try DisableWorkerCommand(di: di),
                try ToggleWorkersSharingCommand(di: di),
                VersionCommand(),
            ],
            helpCommandType: .generateAutomatically
        )
        let invokableCommand = try commandInvoker.invokableCommand()
        
        di.set(
            try di.get(ContextualLogger.self).withMetadata(key: .emceeCommand, value: invokableCommand.command.name)
        )
        
        try invokableCommand.invoke()
    }
    
    private func setupLogging(di: DI, logsTimeToLive: TimeUnit, queue: OperationQueue) throws -> ContextualLogger {
        let loggingSetup: LoggingSetup = try di.get()
        let logger = try loggingSetup.setupLogging(stderrVerbosity: .info)
        
        try loggingSetup.cleanUpLogs(
            logger: logger,
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
