import Foundation
import Models

public struct WorkerAliveness: Equatable, CustomStringConvertible {
    public enum Status: Equatable, CustomStringConvertible {
        case alive
        case silent(lastAlivenessResponseTimestamp: Date)
        case blocked
        case notRegistered
        
        public var description: String {
            switch self {
            case .alive:
                return "alive"
            case .silent(let lastAlivenessResponseTimestamp):
                return "silent since \(lastAlivenessResponseTimestamp)"
            case .blocked:
                return "blocked"
            case .notRegistered:
                return "not registered"
            }
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
