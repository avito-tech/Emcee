import Foundation
import Models

public struct StuckBucket: Equatable {
    public enum Reason: String, Equatable {
        case workerIsBlocked = "worker is blocked"
        case workerIsSilent = "worker is silent"
    }
    public let reason: Reason
    public let bucket: Bucket
    public let workerId: String
    
    public init(reason: Reason, bucket: Bucket, workerId: String) {
        self.reason = reason
        self.bucket = bucket
        self.workerId = workerId
    }
}
