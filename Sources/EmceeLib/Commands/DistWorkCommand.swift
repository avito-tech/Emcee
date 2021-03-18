import ArgLib
import DI
import DateProvider
import DeveloperDirLocator
import DistWorker
import EmceeVersion
import FileSystem
import Foundation
import EmceeLogging
import LoggingSetup
import Metrics
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
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired,
    ]
    
    private let di: DI
    private let logger: ContextualLogger

    public init(di: DI) throws {
        self.di = di
        self.logger = try di.get(ContextualLogger.self).forType(Self.self)
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        let emceeVersion: Version = try payload.optionalSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name) ?? EmceeVersion.version
        
        di.set(try createScopedTemporaryFolder(), for: TemporaryFolder.self)

        let onDemandSimulatorPool = try OnDemandSimulatorPoolFactory.create(
            di: di,
            logger: logger,
            version: emceeVersion
        )
        defer { onDemandSimulatorPool.deleteSimulators() }
        
        di.set(onDemandSimulatorPool, for: OnDemandSimulatorPool.self)

        let distWorker = try createDistWorker(
            queueServerAddress: queueServerAddress,
            version: emceeVersion,
            workerId: workerId
        )
        
        SignalHandling.addSignalHandler(signals: [.term, .int]) { [logger] signal in
            logger.debug("Got signal: \(signal)")
            onDemandSimulatorPool.deleteSimulators()
        }
        
        try startWorker(distWorker: distWorker, emceeVersion: emceeVersion)
    }
    
    private func createDistWorker(
        queueServerAddress: SocketAddress,
        version: Version,
        workerId: WorkerId
    ) throws -> DistWorker {
        let requestSender = try di.get(RequestSenderProvider.self).requestSender(socketAddress: queueServerAddress)
        
        di.set(WorkerRegistererImpl(requestSender: requestSender), for: WorkerRegisterer.self)
        di.set(BucketResultSenderImpl(requestSender: requestSender), for: BucketResultSender.self)
        di.set(BucketFetcherImpl(requestSender: requestSender), for: BucketFetcher.self)
        
        di.set(
            SimulatorSettingsModifierImpl(
                developerDirLocator: try di.get(),
                processControllerProvider: try di.get(),
                tempFolder: try di.get(),
                uniqueIdentifierGenerator: try di.get()
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
            version: version,
            workerId: workerId
        )
    }
        
    private func startWorker(
        distWorker: DistWorker,
        emceeVersion: Version
    ) throws {
        var isWorking = true
        
        try distWorker.start { isWorking = false }
        
        SignalHandling.addSignalHandler(signals: [.term, .int]) { [logger] signal in
            logger.debug("Got signal: \(signal)")
            isWorking = false
        }
        
        try di.get(Waiter.self).waitWhile(description: "Run Worker") { isWorking }
    }

    private func createScopedTemporaryFolder() throws -> TemporaryFolder {
        let containerPath = AbsolutePath(ProcessInfo.processInfo.executablePath)
            .removingLastComponent
            .appending(component: "tempFolder")
        return try TemporaryFolder(containerPath: containerPath)
    }
}
