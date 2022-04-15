import ArgLib
import EmceeDI
import DateProvider
import DeveloperDirLocator
import DistWorker
import EmceeVersion
import FileSystem
import Foundation
import EmceeLogging
import EmceeLoggingModels
import MetricsRecording
import PathLib
import PluginManager
import ProcessController
import QueueClient
import QueueModels
import RequestSender
import ResourceLocationResolver
import Runner
import SignalHandling
import SimulatorPool
import SocketModels
import SynchronousWaiter
import Tmp
import UniqueIdentifierGenerator
import WorkerCapabilitiesModels
import WorkerCapabilities

public final class DistWorkCommand: Command {
    public let name = "distWork"
    public let description = "Takes jobs from a dist runner queue and performs them"
    public var arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asOptional,
        ArgumentDescriptions.hostname.asRequired,
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired,
    ]
    
    private let di: DI

    public init(di: DI) throws {
        self.di = di
    }
    
    public func run(payload: CommandPayload) throws {
        let hostname: String = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.hostname.name)
        try HostnameSetup.update(hostname: hostname, di: di)

        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        
        let logger = try di.get(ContextualLogger.self)
        let tempFolder = try createScopedTemporaryFolder()

        let onDemandSimulatorPool = try OnDemandSimulatorPoolFactory.create(
            di: di,
            hostname: hostname,
            logger: logger,
            tempFolder: tempFolder,
            version: emceeVersion
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        di.set(onDemandSimulatorPool, for: OnDemandSimulatorPool.self)
        

        let distWorker = try createDistWorker(
            hostname: hostname,
            queueServerAddress: queueServerAddress,
            version: emceeVersion,
            workerId: workerId,
            logger: logger,
            tempFolder: tempFolder
        )
        
        SignalHandling.addSignalHandler(signals: [.term, .int]) { [logger] signal in
            logger.trace("Got signal: \(signal)")
            onDemandSimulatorPool.deleteSimulators()
        }
        
        try startWorker(
            distWorker: distWorker,
            logger: logger
        )
    }
    
    private func createDistWorker(
        hostname: String,
        queueServerAddress: SocketAddress,
        version: Version,
        workerId: WorkerId,
        logger: ContextualLogger,
        tempFolder: TemporaryFolder
    ) throws -> DistWorker {
        let requestSender = try di.get(RequestSenderProvider.self).requestSender(socketAddress: queueServerAddress)
        
        di.set(WorkerRegistererImpl(requestSender: requestSender), for: WorkerRegisterer.self)
        di.set(BucketResultSenderImpl(requestSender: requestSender), for: BucketResultSender.self)
        di.set(BucketFetcherImpl(requestSender: requestSender), for: BucketFetcher.self)
        
        di.set(
            SimulatorSettingsModifierImpl(
                developerDirLocator: try di.get(),
                processControllerProvider: try di.get(),
                tempFolder: tempFolder,
                uniqueIdentifierGenerator: try di.get(),
                resourceLocationResolver: try di.get()
            ),
            for: SimulatorSettingsModifier.self
        )
        di.set(
            JoinedCapabilitiesProvider(
                providers: [
                    XcodeCapabilitiesProvider(
                        fileSystem: try di.get(),
                        logger: logger
                    ),
                    SimRuntimeCapabilitiesProvider(
                        fileSystem: try di.get(),
                        logger: logger
                    ),
                    OperatingSystemCapabilitiesProvider(
                        operatingSystemVersionProvider: ProcessInfo.processInfo
                    ),
                ]
            ),
            for: WorkerCapabilitiesProvider.self
        )
        
        let updatedLogger = try di.get(ContextualLogger.self)
            .withMetadata(key: .workerId, value: workerId.value)
            .withMetadata(key: .emceeVersion, value: version.value)
        di.set(updatedLogger)
        
        return try DistWorker(
            di: di,
            hostname: hostname,
            resourceLocationResolver: try di.get(),
            tempFolder: tempFolder,
            version: version,
            workerId: workerId
        )
    }
        
    private func startWorker(
        distWorker: DistWorker,
        logger: ContextualLogger
    ) throws {
        var isWorking = true
        
        try distWorker.start { isWorking = false }
        
        SignalHandling.addSignalHandler(signals: [.term, .int]) { [logger] signal in
            logger.trace("Got signal: \(signal)")
            isWorking = false
        }
        
        try di.get(Waiter.self).waitWhile(description: "Run Worker") { isWorking }
    }

    private func createScopedTemporaryFolder() throws -> TemporaryFolder {
        let containerPath = AbsolutePath(ProcessInfo.processInfo.executablePath)
            .removingLastComponent
            .appending("tempFolder")
        return try TemporaryFolder(containerPath: containerPath)
    }
}
