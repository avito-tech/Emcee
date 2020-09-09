import Foundation
import QueueModels
import RESTInterfaces
import WorkerCapabilitiesModels

public final class DequeueBucketPayload: Codable, SignedPayload {
    public let payloadSignature: PayloadSignature
    public let workerCapabilities: Set<WorkerCapability>
    public let workerId: WorkerId
    
    public init(
        payloadSignature: PayloadSignature,
        workerCapabilities: Set<WorkerCapability>,
        workerId: WorkerId
    ) {
        self.payloadSignature = payloadSignature
        self.workerCapabilities = workerCapabilities
        self.workerId = workerId
    }
}
