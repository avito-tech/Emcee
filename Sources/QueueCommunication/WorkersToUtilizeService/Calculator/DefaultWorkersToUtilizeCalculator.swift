import EmceeLogging
import QueueModels
import Types

private typealias VersionClusters = MapWithCollection<[Version], WorkerId>

public class DefaultWorkersToUtilizeCalculator: WorkersToUtilizeCalculator {
    private let logger: ContextualLogger
    
    public init(logger: ContextualLogger) {
        self.logger = logger
    }
    
    public func disjointWorkers(mapping: WorkersPerVersion) -> WorkersPerVersion {
        logger.debug("Received workers to disjoint: \(mapping)")
        let calculatedMapping = calculateMapping(clusters: splitDestinationsToClusters(mapping: mapping))
        logger.debug("Disjoint workers: \(calculatedMapping)")
        return calculatedMapping
    }
    
    // Map destinations to list of its emcee versions
    private func splitDestinationsToClusters(mapping: WorkersPerVersion) -> VersionClusters {
        var owners = MapWithCollection<WorkerId, Version>()
        for (version, deployments) in mapping {
            for deployment in deployments {
                owners.append(key: deployment, element: version)
            }
        }
        
        var clusters = VersionClusters()
        for (deployment, version) in owners.asDictionary {
            clusters.append(key: version, element: deployment)
        }
        
        return clusters
    }
    
    // Calculates dedicated deployments per emcee version
    // For each cluster share its deployments as evenly as possible
    // Cyclically iterating over version and deployments until all of them is processed
    private func calculateMapping(clusters: VersionClusters) -> WorkersPerVersion {
        var mapping = MapWithCollection<Version, WorkerId>()
        
        for (cluster, workerIds) in clusters.asDictionary {
            let sortedWorkerIds = workerIds.sorted()
            let sortedCluster = cluster.sorted()
            
            for i in 0..<max(sortedCluster.count, sortedWorkerIds.count) {
                let version = sortedCluster.cyclicSubscript(i)
                let workerId = sortedWorkerIds.cyclicSubscript(i)
                mapping.append(key: version, element: workerId)
            }
        }
        
        return mapping.asDictionary.mapValues { Set($0) }
    }
}
