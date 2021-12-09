import Foundation
import QueueModels

public protocol SchedulerDelegate: AnyObject {
    func scheduler(
        _ sender: Scheduler,
        obtainedBucketResult bucketResult: BucketResult,
        forBucket bucket: SchedulerBucket
    )
}
