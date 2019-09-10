import ArgLib
import DistWorker
import Foundation
import Logging
import LoggingSetup
import Models
import PathLib
import ResourceLocationResolver
import RequestSender
import SimulatorPool
import TemporaryStuff
import QueueClient

public final class DistWorkCommand: Command {
    public let name = "distWork"
    public let description = "Takes jobs from a dist runner queue and performs them"
    public var arguments: Arguments = [
        ArgumentDescriptions.queueServer.asRequired,
        ArgumentDescriptions.workerId.asRequired
    ]
    
    private let resourceLocationResolver: ResourceLocationResolver
    
    public init(resourceLocationResolver: ResourceLocationResolver) {
        self.resourceLocationResolver = resourceLocationResolver
    }
    
    public func run(payload: CommandPayload) throws {
        let queueServerAddress: SocketAddress = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.queueServer.name)
        let workerId: WorkerId = try payload.expectedSingleTypedValue(argumentName: ArgumentDescriptions.workerId.name)
        let temporaryFolder = try createScopedTemporaryFolder()

        let onDemandSimulatorPool = OnDemandSimulatorPoolFactory.create(
            resourceLocationResolver: resourceLocationResolver,
            tempFolder: temporaryFolder
        )
        defer { onDemandSimulatorPool.deleteSimulators() }

        let distWorker = self.distWorker(
            queueServerAddress: queueServerAddress,
            workerId: workerId,
            temporaryFolder: temporaryFolder,
            onDemandSimulatorPool: onDemandSimulatorPool
        )
        
        startWorker(distWorker: distWorker)
    }
    
    private func distWorker(
        queueServerAddress: SocketAddress,
        workerId: WorkerId,
        temporaryFolder: TemporaryFolder,
        onDemandSimulatorPool: OnDemandSimulatorPool
    ) -> DistWorker {
        let requestSender = DefaultRequestSenderProvider().requestSender(socketAddress: queueServerAddress)
        
        let reportAliveSender = ReportAliveSenderImpl(requestSender: requestSender)
        let workerRegisterer = WorkerRegistererImpl(requestSender: requestSender)
        let bucketResultSender = BucketResultSenderImpl(requestSender: requestSender)
        
        return DistWorker(
            onDemandSimulatorPool: onDemandSimulatorPool,
            queueClient: SynchronousQueueClient(queueServerAddress: queueServerAddress),
            workerId: workerId,
            resourceLocationResolver: resourceLocationResolver,
            temporaryFolder: temporaryFolder,
            testRunnerProvider: DefaultTestRunnerProvider(
                resourceLocationResolver: resourceLocationResolver
            ),
            reportAliveSender: reportAliveSender,
            workerRegisterer: workerRegisterer,
            bucketResultSender: bucketResultSender
        )
    }
        
    private func startWorker(distWorker: DistWorker) {
        let dispatchQueue = DispatchQueue(label: "DistWorker.queue")
        let dispatchGroup = DispatchGroup()
        
        dispatchGroup.enter()
        dispatchQueue.async {
            do {
                try distWorker.start(
                    didFetchAnalyticsConfiguration: { analyticsConfiguration in
                        try LoggingSetup.setupAnalytics(analyticsConfiguration: analyticsConfiguration)
                    },
                    completion: {
                        dispatchGroup.leave()
                    }
                )
            } catch {
                Logger.error("\(error)")
                dispatchGroup.leave()
            }
            
            dispatchGroup.wait()
        }
    }

    private func createScopedTemporaryFolder() throws -> TemporaryFolder {
        let containerPath = AbsolutePath(ProcessInfo.processInfo.executablePath)
            .removingLastComponent
            .appending(component: "tempFolder")
        return try TemporaryFolder(containerPath: containerPath)
    }
}
