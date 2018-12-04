import Foundation

public struct WorkerAliveness: Equatable {
    public enum Status: Equatable {
        case alive
        case silent
        case blocked
        case notRegistered
    }
    
    public let status: Status
    public let bucketIdsBeingProcessed: Set<String>

    public init(status: Status, bucketIdsBeingProcessed: Set<String>) {
        self.status = status
        self.bucketIdsBeingProcessed = bucketIdsBeingProcessed
    }
}
