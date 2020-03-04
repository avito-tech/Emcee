import Foundation
import Models

public final class RegisterWorkerPayload: Codable {
    public let workerId: WorkerId
    public let workerRestPort: Int
    
    public init(workerId: WorkerId, workerRestPort: Int) {
        self.workerId = workerId
        self.workerRestPort = workerRestPort
    }
}
