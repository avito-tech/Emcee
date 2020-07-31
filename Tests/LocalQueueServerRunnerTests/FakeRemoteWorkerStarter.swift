import DistDeployer
import Foundation
import QueueModels
import SocketModels

public final class FakeRemoteWorkerStarter: RemoteWorkerStarter {
    public init() {}
    
    public var deployQueueAddress: SocketAddress?
    
    public func deployAndStartWorker(queueAddress: SocketAddress) throws {
        deployQueueAddress = queueAddress
    }
}
