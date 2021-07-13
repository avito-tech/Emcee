import Deployer
import QueueModels

public typealias WorkersPerVersion = [Version: [WorkerId]]

public protocol WorkersToUtilizeCalculator {
    func disjointWorkers(mapping: WorkersPerVersion) -> WorkersPerVersion
}
