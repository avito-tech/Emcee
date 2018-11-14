import Foundation
import Models
import Scheduler

public final class DistRunSchedulerDataSource: SchedulerDataSource {
    
    private let onNextBucketRequest: () -> SchedulerBucket?

    public init(onNextBucketRequest: @escaping () -> SchedulerBucket?) {
        self.onNextBucketRequest = onNextBucketRequest
    }
    
    public func nextBucket() -> SchedulerBucket? {
        return onNextBucketRequest()
    }
}
