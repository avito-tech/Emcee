import Foundation
import Models

public final class DisableWorkerPayload: Codable {
    public let workerId: WorkerId
    
    public init(
        workerId: WorkerId
    ) {
        self.workerId = workerId
    }
}
