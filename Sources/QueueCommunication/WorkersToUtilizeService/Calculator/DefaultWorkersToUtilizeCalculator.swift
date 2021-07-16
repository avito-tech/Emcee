import EmceeLogging
import QueueModels
import Types

private typealias VersionClusters = MapWithCollection<[QueueInfo], WorkerId>

public class DefaultWorkersToUtilizeCalculator: WorkersToUtilizeCalculator {
    private let logger: ContextualLogger
    
    public init(logger: ContextualLogger) {
        self.logger = logger
    }
    
    public func disjointWorkers(mapping: WorkersPerQueue) -> WorkersPerQueue {
        logger.debug("Received workers to disjoint: \(mapping)")
        let calculatedMapping = calculateMapping(clusters: splitDestinationsToClusters(mapping: mapping))
        logger.debug("Disjoint workers: \(calculatedMapping)")
        return calculatedMapping
    }
    
    // Map destinations to list of its emcee versions
    private func splitDestinationsToClusters(mapping: WorkersPerQueue) -> VersionClusters {
        let mapping = mapping.sorted { left, right in
            left.key < right.key
        }
        
        var owners = MapWithCollection<WorkerId, QueueInfo>()
        
        for (queueInfo, workerIds) in mapping {
            for workerId in workerIds {
                owners.append(
                    key: workerId,
                    element: queueInfo
                )
            }
        }
        
        var clusters = VersionClusters()
        for (workerId, queueInfo) in owners.asDictionary {
            clusters.append(key: queueInfo, element: workerId)
        }
        
        return clusters
    }
    
    // Calculates dedicated worker ids per queue
    // For each cluster share its workers as evenly as possible
    // Cyclically iterating over version and workers until all of them is processed
    private func calculateMapping(clusters: VersionClusters) -> WorkersPerQueue {
        var mapping = MapWithCollection<QueueInfo, WorkerId>()
        
        for (cluster, workerIds) in clusters.asDictionary {
            let sortedWorkerIds = workerIds.sorted()
            let sortedCluster = cluster.sorted()
            
            for i in 0..<max(sortedCluster.count, sortedWorkerIds.count) {
                let queueInfo = sortedCluster.cyclicSubscript(i)
                let workerId = sortedWorkerIds.cyclicSubscript(i)
                mapping.append(key: queueInfo, element: workerId)
            }
        }
        
        return mapping.asDictionary.mapValues { Set($0) }
    }
}
