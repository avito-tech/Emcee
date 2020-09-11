import QueueModels

public protocol RunningQueueStateProvider {
    var runningQueueState: RunningQueueState { get }
}
