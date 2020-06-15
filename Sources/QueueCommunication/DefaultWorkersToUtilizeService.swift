import Deployer
import Foundation
import Models

public class DefaultWorkersToUtilizeService: WorkersToUtilizeService {    
    public init() {
        
    }
    
    public func workersToUtilize(deployments: [DeploymentDestination], version: Version) -> [WorkerId] {
        return deployments.map { $0.workerId }
    }
}
