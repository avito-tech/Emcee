import Foundation
import QueueModels

public protocol CurrentlyBeingProcessedBucketsTracker {
    func willProcess(bucketId: BucketId)
    func didProcess(bucketId: BucketId)
    
    var bucketIdsBeingProcessed: Set<BucketId> { get }
}
