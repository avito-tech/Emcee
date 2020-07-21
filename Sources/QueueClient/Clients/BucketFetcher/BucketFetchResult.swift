import Foundation
import QueueModels

public enum BucketFetchResult: Equatable {
    case bucket(Bucket)
    case queueIsEmpty
    case checkLater(TimeInterval)
    case workerNotRegistered
}
