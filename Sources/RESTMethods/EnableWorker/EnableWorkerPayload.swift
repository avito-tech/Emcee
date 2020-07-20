import Foundation
import QueueModels

public final class EnableWorkerPayload: Codable {
    public let workerId: WorkerId
    
    public init(
        workerId: WorkerId
    ) {
        self.workerId = workerId
    }
}
