import Foundation
import Models

public protocol BucketQueue {
    var state: BucketQueueState { get }
    func enqueue(buckets: [Bucket])
    func dequeueBucket(requestId: String, workerId: String) -> DequeueResult
    func accept(testingResult: TestingResult, requestId: String, workerId: String) throws -> BucketQueueAcceptResult
    func reenqueueStuckBuckets() -> [StuckBucket]
}
