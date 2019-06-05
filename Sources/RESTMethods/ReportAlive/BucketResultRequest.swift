import Foundation
import Models

public final class ReportAliveRequest: Codable, SignedRequest {
    public let workerId: String
    public let bucketIdsBeingProcessed: Set<String>
    public let requestSignature: RequestSignature
    
    public init(
        workerId: String,
        bucketIdsBeingProcessed: Set<String>,
        requestSignature: RequestSignature
    ) {
        self.workerId = workerId
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
        self.requestSignature = requestSignature
    }
}
