import Foundation
import Models

public final class ReportAlivePayload: Codable, SignedPayload {
    public let workerId: WorkerId
    public let bucketIdsBeingProcessed: Set<BucketId>
    public let payloadSignature: PayloadSignature
    
    public init(
        workerId: WorkerId,
        bucketIdsBeingProcessed: Set<BucketId>,
        payloadSignature: PayloadSignature
    ) {
        self.workerId = workerId
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
        self.payloadSignature = payloadSignature
    }
}
