import BucketQueue
import Foundation

/// Allows to override dequeue result when no dequeueable buckets available.
public protocol NothingToDequeueBehavior {
    func dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: [DequeueResult]) -> DequeueResult
}

/// This behavior will not let workers quit, making them check for new jobs again and again.
public final class NothingToDequeueBehaviorCheckLater: NothingToDequeueBehavior {
    private let checkAfter: TimeInterval

    public init(checkAfter: TimeInterval) {
        self.checkAfter = checkAfter
    }
    
    public func dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: [DequeueResult]) -> DequeueResult {
        return .checkAgainLater(checkAfter: checkAfter)
    }
}
