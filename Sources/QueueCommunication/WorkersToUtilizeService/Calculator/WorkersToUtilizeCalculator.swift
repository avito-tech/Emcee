public protocol WorkersToUtilizeCalculator {
    /// Calculates a new rebalanced mapping based on initial assignment of worker ids for each queue.
    /// - Parameter mapping: Initial assigmnet of worker ids for each queue in form of a map from queue to its worker ids
    func disjointWorkers(mapping: WorkersPerQueue) -> WorkersPerQueue
}
