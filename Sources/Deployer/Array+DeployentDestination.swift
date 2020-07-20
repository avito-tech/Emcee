import QueueModels

public extension Array where Element == DeploymentDestination {
    func workerIds() -> [WorkerId] {
        return self.map { $0.workerId }
    }
}
