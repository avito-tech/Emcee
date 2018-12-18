import Foundation

public protocol DequeueableBucketSource {
    func previouslyDequeuedBucket(requestId: String, workerId: String) -> DequeuedBucket?
    func dequeueBucket(requestId: String, workerId: String) -> DequeueResult
}
