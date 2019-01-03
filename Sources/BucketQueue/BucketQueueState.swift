import Foundation
import Logging

public final class BucketQueueState: Equatable {
    public let enqueuedBucketCount: Int
    public let dequeuedBucketCount: Int
    
    public init(enqueuedBucketCount: Int, dequeuedBucketCount: Int) {
        self.enqueuedBucketCount = enqueuedBucketCount
        self.dequeuedBucketCount = dequeuedBucketCount
    }
    
    public var isDepleted: Bool {
        return enqueuedBucketCount == 0 && dequeuedBucketCount == 0
    }
    
    public static func == (left: BucketQueueState, right: BucketQueueState) -> Bool {
        return left.enqueuedBucketCount == right.enqueuedBucketCount &&
            left.dequeuedBucketCount == right.dequeuedBucketCount
    }
}

public final class BucketQueueStateLogger {
    private let state: BucketQueueState
    
    public init(state: BucketQueueState) {
        self.state = state
    }
    
    public func logQueueSize() {
        Logger.info("Enqueued buckets: \(state.enqueuedBucketCount), dequeued buckets: \(state.dequeuedBucketCount)")
    }
}
