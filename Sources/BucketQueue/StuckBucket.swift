import Foundation
import Models

public struct StuckBucket: Equatable {
    public enum Reason: String, Equatable {
        case workerIsBlocked = "worker is blocked"
        case workerIsSilent = "worker is silent"
        case bucketLost = "worker has been processing bucket but then switched to another bucket"
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
