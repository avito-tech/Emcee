import Dispatch
import Deployer
import DistDeployer
import Foundation
import QueueModels
import QueueServer
import QueueServerPortProvider
import SocketModels

public final class OnDemandWorkerStarterViaDeployer: OnDemandWorkerStarter {
    private let hostname: String
    private let queueServerPortProvider: QueueServerPortProvider
    private let remoteWorkerStarterProvider: RemoteWorkerStarterProvider
    
    public init(
        hostname: String,
        queueServerPortProvider: QueueServerPortProvider,
        remoteWorkerStarterProvider: RemoteWorkerStarterProvider
    ) {
        self.hostname = hostname
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
            queueAddress: SocketAddress(
                host: hostname,
                port: try queueServerPortProvider.port()
            )
        )
    }
}
