import Models
import QueueCommunication

public class FakeWorkersToUtilizeService: WorkersToUtilizeService {
    public init() { }
    
    public func workersToUtilize(initialWorkers: [WorkerId], version: Version) -> [WorkerId] {
        return []
    }
}
