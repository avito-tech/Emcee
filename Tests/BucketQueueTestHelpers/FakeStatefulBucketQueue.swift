import BucketQueue
import Foundation
import QueueModels

open class FakeStatefulBucketQueue: StatefulBucketQueue {
    public var resultProvider: () -> RunningQueueState
    
    public init(
        resultProvider: @escaping () -> RunningQueueState = {
            RunningQueueState(
                enqueuedBucketCount: 0,
                enqueuedTests: [],
                dequeuedBucketCount: 0,
                dequeuedTests: [:]
            )
        }
    ) {
        self.resultProvider = resultProvider
    }
    
    public var runningQueueState: RunningQueueState {
        set {
            resultProvider = { newValue }
        }
        get {
            resultProvider()
        }
    }
}
