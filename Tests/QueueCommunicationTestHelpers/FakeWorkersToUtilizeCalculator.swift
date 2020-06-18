import QueueCommunication
import DeployerTestHelpers

public class FakeWorkersToUtilizeCalculator: WorkersToUtilizeCalculator {
    public init() { }
    
    public var result: WorkersPerVersion = [:]
    public var receivedMapping: WorkersPerVersion?
    public func disjointWorkers(mapping: WorkersPerVersion) -> WorkersPerVersion {
        receivedMapping = mapping
        return result
    }
}
