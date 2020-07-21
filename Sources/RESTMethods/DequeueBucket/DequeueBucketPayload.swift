import Foundation
import QueueModels
import RESTInterfaces
import WorkerCapabilitiesModels

public final class DequeueBucketPayload: Codable, SignedPayload {
    public let payloadSignature: PayloadSignature
    public let requestId: RequestId
    public let workerCapabilities: Set<WorkerCapability>
    public let workerId: WorkerId
    
    public init(
        payloadSignature: PayloadSignature,
        requestId: RequestId,
        workerCapabilities: Set<WorkerCapability>,
        workerId: WorkerId
    ) {
        self.payloadSignature = payloadSignature
        self.requestId = requestId
        self.workerCapabilities = workerCapabilities
        self.workerId = workerId
    }
}
