import Foundation
import Models

public struct StuckBucket: Equatable {
    public enum Reason: String, Equatable, CustomStringConvertible {
        case workerIsBlocked
        case workerIsSilent
        case bucketLost
        
        public var description: String {
            switch self {
            case .workerIsSilent:
                return "worker is silent"
            case .workerIsBlocked:
                return "worker is blocked"
            case .bucketLost:
                return "worker has been processing bucket but then switched to another bucket"
            }
        }
    }
    
    public let reason: Reason
    public let bucket: Bucket
    public let workerId: String
    public let requestId: String
    
    public init(reason: Reason, bucket: Bucket, workerId: String, requestId: String) {
        self.reason = reason
        self.bucket = bucket
        self.workerId = workerId
        self.requestId = requestId
    }
}
