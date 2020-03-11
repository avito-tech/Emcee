import ArgLib
import DateProvider
import DeveloperDirLocator
import DistWorker
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import PluginManager
import ProcessController
import QueueClient
import RequestSender
import ResourceLocationResolver
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import UniqueIdentifierGenerator

public final class DistWorkCommand: Command {
    public let name = "distWork"
    public let description = "Takes jobs from a dist runner queue and performs them"
    public var arguments: Arguments = [
        ArgumentDescriptions.emceeVersion.asRequired,
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired
    ]
    
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let processControllerProvider: ProcessControllerProvider
    private let pluginEventBusProvider: PluginEventBusProvider
    private let requestSenderProvider: RequestSenderProvider
    private let resourceLocationResolver: ResourceLocationResolver
    private let uniqueIdentifierGenerator: UniqueIdentifierGenerator

    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        pluginEventBusProvider: PluginEventBusProvider,
        processControllerProvider: ProcessControllerProvider,
        requestSenderProvider: RequestSenderProvider,
        resourceLocationResolver: ResourceLocationResolver,
        uniqueIdentifierGenerator: UniqueIdentifierGenerator
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.pluginEventBusProvider = pluginEventBusProvider
        self.processControllerProvider = processControllerProvider
        self.requestSenderProvider = requestSenderProvider
        self.resourceLocationResolver = resourceLocationResolver
        self.uniqueIdentifierGenerator = uniqueIdentifierGenerator
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        let emceeVersion: Version = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.emceeVersion.name)
        let temporaryFolder = try createScopedTemporaryFolder()

        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            developerDirLocator: developerDirLocator,
            processControllerProvider: processControllerProvider,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: temporaryFolder,
            uniqueIdentifierGenerator: uniqueIdentifierGenerator
        )
        defer { onDemandSimulatorPool.deleteSimulators() }

        let distWorker = createDistWorker(
            onDemandSimulatorPool: onDemandSimulatorPool,
            queueServerAddress: queueServerAddress,
            temporaryFolder: temporaryFolder,
            workerId: workerId
        )
        
        try startWorker(distWorker: distWorker, emceeVersion: emceeVersion)
    }
    
    private func createDistWorker(
        onDemandSimulatorPool: OnDemandSimulatorPool,
        queueServerAddress: SocketAddress,
        temporaryFolder: TemporaryFolder,
        workerId: WorkerId
    ) -> DistWorker {
        let requestSender = requestSenderProvider.requestSender(socketAddress: queueServerAddress)
        
        let reportAliveSender = ReportAliveSenderImpl(requestSender: requestSender)
        let workerRegisterer = WorkerRegistererImpl(requestSender: requestSender)
        let bucketResultSender = BucketResultSenderImpl(requestSender: requestSender)
        
        return DistWorker(
            bucketResultSender: bucketResultSender,
            developerDirLocator: developerDirLocator,
            onDemandSimulatorPool: onDemandSimulatorPool,
            pluginEventBusProvider: pluginEventBusProvider,
            queueClient: SynchronousQueueClient(queueServerAddress: queueServerAddress),
            reportAliveSender: reportAliveSender,
            resourceLocationResolver: resourceLocationResolver,
            temporaryFolder: temporaryFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                dateProvider: dateProvider,
                processControllerProvider: processControllerProvider,
                resourceLocationResolver: resourceLocationResolver
            ),
            workerId: workerId,
            workerRegisterer: workerRegisterer
        )
    }
        
    private func startWorker(distWorker: DistWorker, emceeVersion: Version) throws {
        var isWorking = true
        
        try distWorker.start(
            didFetchAnalyticsConfiguration: { analyticsConfiguration in
                try LoggingSetup.setupAnalytics(analyticsConfiguration: analyticsConfiguration, emceeVersion: emceeVersion)
            },
            completion: {
                isWorking = false
            }
        )
        
        try SynchronousWaiter().waitWhile { isWorking }
    }

    private func createScopedTemporaryFolder() throws -> TemporaryFolder {
        let containerPath = AbsolutePath(ProcessInfo.processInfo.executablePath)
            .removingLastComponent
            .appending(component: "tempFolder")
        return try TemporaryFolder(containerPath: containerPath)
    }
}
