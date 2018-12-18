import Foundation

public protocol QueueStateProvider {
    var state: BucketQueueState { get }
}
