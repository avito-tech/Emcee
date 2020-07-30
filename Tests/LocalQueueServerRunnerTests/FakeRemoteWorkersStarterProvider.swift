import DistDeployer
import Foundation
import LocalQueueServerRunner
import QueueModels

public final class FakeRemoteWorkerStarterProvider: RemoteWorkerStarterProvider {
    public init() {}
    
    public func remoteWorkerStarter(workerId: WorkerId) throws -> RemoteWorkerStarter {
        FakeRemoteWorkerStarter()
    }
}
