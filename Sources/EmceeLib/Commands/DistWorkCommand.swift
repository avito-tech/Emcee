import ArgLib
import DateProvider
import DeveloperDirLocator
import DistWorker
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import ResourceLocationResolver
import RequestSender
import SimulatorPool
import SynchronousWaiter
import TemporaryStuff
import QueueClient

public final class DistWorkCommand: Command {
    public let name = "distWork"
    public let description = "Takes jobs from a dist runner queue and performs them"
    public var arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired
    ]
    
    private let dateProvider: DateProvider
    private let developerDirLocator: DeveloperDirLocator
    private let requestSenderProvider: RequestSenderProvider
    private let resourceLocationResolver: ResourceLocationResolver

    public init(
        dateProvider: DateProvider,
        developerDirLocator: DeveloperDirLocator,
        requestSenderProvider: RequestSenderProvider,
        resourceLocationResolver: ResourceLocationResolver
    ) {
        self.dateProvider = dateProvider
        self.developerDirLocator = developerDirLocator
        self.requestSenderProvider = requestSenderProvider
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        let temporaryFolder = try createScopedTemporaryFolder()

        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            developerDirLocator: developerDirLocator,
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: temporaryFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }

        let distWorker = createDistWorker(
            onDemandSimulatorPool: onDemandSimulatorPool,
            queueServerAddress: queueServerAddress,
            temporaryFolder: temporaryFolder,
            workerId: workerId
        )
        
        try startWorker(distWorker: distWorker)
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
            queueClient: SynchronousQueueClient(queueServerAddress: queueServerAddress),
            reportAliveSender: reportAliveSender,
            resourceLocationResolver: resourceLocationResolver,
            temporaryFolder: temporaryFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                dateProvider: dateProvider,
                resourceLocationResolver: resourceLocationResolver
            ),
            workerId: workerId,
            workerRegisterer: workerRegisterer
        )
    }
        
    private func startWorker(distWorker: DistWorker) throws {
        var isWorking = true
        
        try distWorker.start(
            didFetchAnalyticsConfiguration: { analyticsConfiguration in
                try LoggingSetup.setupAnalytics(analyticsConfiguration: analyticsConfiguration)
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
