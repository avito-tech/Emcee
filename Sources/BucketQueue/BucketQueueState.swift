import Foundation
import Logging

public final class BucketQueueState {
    public let enqueuedBucketCount: Int
    public let dequeuedBucketCount: Int
    
    public init(enqueuedBucketCount: Int, dequeuedBucketCount: Int) {
        self.enqueuedBucketCount = enqueuedBucketCount
        self.dequeuedBucketCount = dequeuedBucketCount
    }
    
    public var isDepleted: Bool {
        return enqueuedBucketCount == 0 && dequeuedBucketCount == 0
    }
}

public final class BucketQueueStateLogger {
    private let state: BucketQueueState
    
    public init(state: BucketQueueState) {
        self.state = state
    }
    
    public func logQueueSize() {
        log("Enqueued buckets: \(state.enqueuedBucketCount), dequeued buckets: \(state.dequeuedBucketCount)")
    }
}
