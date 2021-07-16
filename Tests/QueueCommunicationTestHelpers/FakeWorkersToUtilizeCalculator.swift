import QueueCommunication
import DeployerTestHelpers

public class FakeWorkersToUtilizeCalculator: WorkersToUtilizeCalculator {
    public init() { }
    
    public var result: WorkersPerQueue = [:]
    public var receivedMapping: WorkersPerQueue?
    public func disjointWorkers(mapping: WorkersPerQueue) -> WorkersPerQueue {
        receivedMapping = mapping
        return result
    }
}
