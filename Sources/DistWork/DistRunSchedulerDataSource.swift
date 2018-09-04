import Foundation
import Models
import Scheduler

public final class DistRunSchedulerDataSource: SchedulerDataSource {
    
    private let onNextBucketRequest: () -> Bucket?

    public init(onNextBucketRequest: @escaping () -> Bucket?) {
        self.onNextBucketRequest = onNextBucketRequest
    }
    
    public func nextBucket() -> Bucket? {
        return onNextBucketRequest()
    }
}
