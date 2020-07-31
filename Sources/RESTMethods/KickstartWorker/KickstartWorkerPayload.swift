import Foundation
import QueueModels

public final class KickstartWorkerPayload: Codable {
    public let workerId: WorkerId
    
    public init(
        workerId: WorkerId
    ) {
        self.workerId = workerId
    }
}
