import Foundation
import Models

public final class ReportAliveRequest: Codable, SignedRequest {
    public let workerId: WorkerId
    public let bucketIdsBeingProcessed: Set<BucketId>
    public let requestSignature: RequestSignature
    
    public init(
        workerId: WorkerId,
        bucketIdsBeingProcessed: Set<BucketId>,
        requestSignature: RequestSignature
    ) {
        self.workerId = workerId
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
        self.requestSignature = requestSignature
    }
}
