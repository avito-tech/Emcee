import Foundation
import EmceeLogging
import QueueModels

public struct StuckBucket: Equatable {
    public enum Reason: Equatable, CustomStringConvertible {
        case workerIsSilent
        case bucketLost
        
        public var description: String {
            switch self {
            case .workerIsSilent:
                return "worker is silent"
            case .bucketLost:
                return "worker has been processing bucket but then switched to another bucket"
            }
        }
    }
    
    public let reason: Reason
    public let bucket: Bucket
    public let workerId: WorkerId
    
    public init(reason: Reason, bucket: Bucket, workerId: WorkerId) {
        self.reason = reason
        self.bucket = bucket
        self.workerId = workerId
    }
}
