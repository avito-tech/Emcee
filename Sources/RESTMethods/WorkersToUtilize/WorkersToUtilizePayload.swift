import Deployer
import QueueModels

public class WorkersToUtilizePayload: Codable {
    public let version: Version
    public let workerIds: Set<WorkerId>
    
    public init(
        version: Version,
        workerIds: Set<WorkerId>
    ) {
        self.workerIds = workerIds
        self.version = version
    }
}
