import Dispatch
import Deployer
import DistDeployer
import Foundation
import QueueModels
import QueueServer
import QueueServerPortProvider
import SocketModels

public final class OnDemandWorkerStarterViaDeployer: OnDemandWorkerStarter {
    private let queueServerPortProvider: QueueServerPortProvider
    private let remoteWorkerStarterProvider: RemoteWorkerStarterProvider
    
    public init(
        queueServerPortProvider: QueueServerPortProvider,
        remoteWorkerStarterProvider: RemoteWorkerStarterProvider
    ) {
        self.queueServerPortProvider = queueServerPortProvider
        self.remoteWorkerStarterProvider = remoteWorkerStarterProvider
    }
    
    public enum StarterError: Error {
        case unknownWorkerId(WorkerId)
    }
    
    public func start(workerId: WorkerId) throws {
        let starter = try remoteWorkerStarterProvider.remoteWorkerStarter(
            workerId: workerId
        )
        try starter.deployAndStartWorker(
            queueAddress: LocalQueueServerRunner.queueServerAddress(
                port: try queueServerPortProvider.port()
            )
        )
    }
}
