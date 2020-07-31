import DistDeployer
import Foundation
import LocalQueueServerRunner
import QueueModels

public final class FakeRemoteWorkerStarterProvider: RemoteWorkerStarterProvider {
    public init() {}
    
    public var provider: (WorkerId) -> RemoteWorkerStarter = { _ in FakeRemoteWorkerStarter() }
    
    public func remoteWorkerStarter(workerId: WorkerId) throws -> RemoteWorkerStarter {
        provider(workerId)
    }
}
