import Foundation
import Models

public struct WorkerAliveness: Equatable, CustomStringConvertible {
    public enum Status: String, Equatable, CustomStringConvertible {
        case alive
        case silent
        case blocked
        case notRegistered
        
        public var description: String {
            return rawValue
        }
    }
    
    public let status: Status
    public let bucketIdsBeingProcessed: Set<BucketId>

    public init(status: Status, bucketIdsBeingProcessed: Set<BucketId>) {
        self.status = status
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
    }
    
    public var description: String {
        return "\(status), processing bucket ids: \(bucketIdsBeingProcessed.sorted())"
    }
}
