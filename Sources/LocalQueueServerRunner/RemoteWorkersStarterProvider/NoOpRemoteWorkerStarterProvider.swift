import DistDeployer
import EmceeLogging
import Foundation
import QueueModels
import SocketModels

public final class NoOpRemoteWorkerStarterProvider: RemoteWorkerStarterProvider {
    private let logger: ContextualLogger
    
    public init(logger: ContextualLogger) {
        self.logger = logger
    }
    
    public func remoteWorkerStarter(workerId: WorkerId) throws -> RemoteWorkerStarter {
        logger.trace("Request to start worker \(workerId) will be ignored")
        
        return NoOpRemoteWorkerStarter()
    }
}

public final class NoOpRemoteWorkerStarter: RemoteWorkerStarter {
    public init() {}
    
    public func deployAndStartWorker(queueAddress: SocketAddress) throws {
        
    }
}
