import QueueCommunication
import QueueModels

public class FakeWorkersToUtilizeService: WorkersToUtilizeService {
    public init() { }
    
    public func workersToUtilize(initialWorkers: Set<WorkerId>, version: Version) -> Set<WorkerId> {
        return []
    }
}
