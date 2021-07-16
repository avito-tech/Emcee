import QueueCommunication
import QueueModels

public class FakeWorkersToUtilizeService: WorkersToUtilizeService {
    public init() { }
    
    public func workersToUtilize(initialWorkerIds: Set<WorkerId>, queueInfo: QueueInfo) -> Set<WorkerId> {
        return []
    }
}
