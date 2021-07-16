import Deployer
import QueueModels

public class WorkersToUtilizePayload: Codable {
    public let queueInfo: QueueInfo
    public let workerIds: Set<WorkerId>
    
    public init(
        queueInfo: QueueInfo,
        workerIds: Set<WorkerId>
    ) {
        self.queueInfo = queueInfo
        self.workerIds = workerIds
    }
}
