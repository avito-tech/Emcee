import Deployer
import Logging
import QueueModels
import Types

private typealias VersionClusters = MapWithCollection<[Version], WorkerId>

public class DefaultWorkersToUtilizeCalculator: WorkersToUtilizeCalculator {
    public init() { }
    
    public func disjointWorkers(mapping: WorkersPerVersion) -> WorkersPerVersion {
        Logger.info("Received workers to disjoint: \(mapping)")
        let calculatedMapping = calculateMapping(clusters: splitDestinationsToClusters(mapping: mapping))
        Logger.info("Disjoint workers: \(calculatedMapping)")
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
        
        for (cluster, deployments) in clusters.asDictionary {
            let sortedDeployments = deployments.sorted()
            let sortedCluster = cluster.sorted()
            
            for i in 0..<max(sortedCluster.count, sortedDeployments.count) {
                let version = sortedCluster.cyclicSubscript(i)
                let deployment = sortedDeployments.cyclicSubscript(i)
                mapping.append(key: version, element: deployment)
            }
        }
        
        return mapping.asDictionary
    }
}
