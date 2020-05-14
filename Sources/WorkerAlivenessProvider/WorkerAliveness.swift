import Foundation
import Models

public struct WorkerAliveness: Equatable, CustomStringConvertible {
    public enum Status: Equatable, CustomStringConvertible {
        /// worker is yet to register with queue
        case notRegistered
        
        /// worker is alive and performing
        case alive
        
        /// worker is not responding and considered silent
        case silent(lastAlivenessResponseTimestamp: Date)
        
        /// worker has been disabled
        case disabled
        
        public var description: String {
            switch self {
            case .alive:
                return "alive"
            case .silent(let lastAlivenessResponseTimestamp):
                return "silent since \(lastAlivenessResponseTimestamp)"
            case .notRegistered:
                return "not registered"
            case .disabled:
                return "disabled"
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
