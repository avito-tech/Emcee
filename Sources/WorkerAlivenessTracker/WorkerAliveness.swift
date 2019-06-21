import Foundation
import Models

public struct WorkerAliveness: Equatable {
    public enum Status: Equatable {
        case alive
        case silent
        case blocked
        case notRegistered
    }
    
    public let status: Status
    public let bucketIdsBeingProcessed: Set<BucketId>

    public init(status: Status, bucketIdsBeingProcessed: Set<BucketId>) {
        self.status = status
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
    }
}
