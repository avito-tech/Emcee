import DistDeployer
import QueueModels

public protocol RemoteWorkerStarterProvider {
    func remoteWorkerStarter(
        workerId: WorkerId
    ) throws -> RemoteWorkerStarter
}
