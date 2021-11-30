import QueueModels

public protocol StatefulBucketQueue {
    var runningQueueState: RunningQueueState { get }
}
