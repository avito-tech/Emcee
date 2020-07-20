import QueueCommunication
import QueueModels

public class FakeWorkersToUtilizeService: WorkersToUtilizeService {
    public init() { }
    
    public func workersToUtilize(initialWorkers: [WorkerId], version: Version) -> [WorkerId] {
        return []
    }
}
