import Foundation
import QueueModels

public enum BucketFetchResult: Equatable {
    case bucket(Bucket)
    case checkLater(TimeInterval)
}
