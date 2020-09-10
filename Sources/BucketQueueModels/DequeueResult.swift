import Foundation

public enum DequeueResult: Hashable {
    case queueIsEmpty
    case checkAgainLater(checkAfter: TimeInterval)
    case dequeuedBucket(DequeuedBucket)
    case workerIsNotRegistered
}
