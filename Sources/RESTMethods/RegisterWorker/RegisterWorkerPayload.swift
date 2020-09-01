import Foundation
import QueueModels
import SocketModels
import WorkerCapabilitiesModels

public final class RegisterWorkerPayload: Codable {
    public let workerId: WorkerId
    public let workerCapabilities: Set<WorkerCapability>
    public let workerRestAddress: SocketAddress
    
    public init(
        workerId: WorkerId,
        workerCapabilities: Set<WorkerCapability>,
        workerRestAddress: SocketAddress
    ) {
        self.workerId = workerId
        self.workerCapabilities = workerCapabilities
        self.workerRestAddress = workerRestAddress
    }
}
