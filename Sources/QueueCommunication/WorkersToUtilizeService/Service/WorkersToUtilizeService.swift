import QueueModels

public protocol WorkersToUtilizeService {
    /// Returns a set of worker ids that can be utilized by a queue.
    /// - Parameters:
    ///   - initialWorkers: All worker ids that queue was configured to work with.
    ///   - version: Queue version
    func workersToUtilize(
        initialWorkers: Set<WorkerId>,
        version: Version
    ) -> Set<WorkerId>
}
