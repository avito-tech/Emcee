import DistDeployer
import Foundation
import SocketModels

public final class FakeRemoteWorkerStarter: RemoteWorkerStarter {
    public init() {}
    
    public func deployAndStartWorker(queueAddress: SocketAddress) throws {}
}
