import Deployer
import Models

public typealias WorkersPerVersion = [Version: [WorkerId]]

public protocol WorkersToUtilizeCalculator {
    func disjointWorkers(mapping: WorkersPerVersion) -> WorkersPerVersion
}
