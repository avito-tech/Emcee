import Foundation

public final class ReportAliveRequest: Codable {
    public let workerId: String
    public let bucketIdsBeingProcessed: Set<String>
    
    public init(workerId: String, bucketIdsBeingProcessed: Set<String>) {
        self.workerId = workerId
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
    }
}
