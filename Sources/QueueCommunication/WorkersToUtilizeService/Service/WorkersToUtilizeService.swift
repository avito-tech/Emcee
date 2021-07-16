import QueueModels

public protocol WorkersToUtilizeService {
    /// Returns a set of worker ids that can be utilized by a queue.
    /// - Parameters:
    ///   - initialWorkers: All worker ids that queue was configured to work with.
    ///   - queueInfo: Queue information
    func workersToUtilize(
        initialWorkerIds: Set<WorkerId>,
        queueInfo: QueueInfo
    ) -> Set<WorkerId>
}
