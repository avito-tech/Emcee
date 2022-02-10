import BucketQueue
import BucketQueueModels
import Foundation
import QueueModelsTestHelpers
import XCTest

final class SingleEmpyableBucketQueueTests: XCTestCase {
    lazy var bucketQueueHolder = BucketQueueHolder()
    lazy var emptyableQueue = SingleEmptyableBucketQueue(
        bucketQueueHolder: bucketQueueHolder
    )
    
    func test() {
        bucketQueueHolder.insert(
            enqueuedBuckets: [
                EnqueuedBucket(
                    bucket: BucketFixtures().bucket(),
                    enqueueTimestamp: Date(),
                    uniqueIdentifier: "id"
                )
            ],
            position: 0
        )
        
        emptyableQueue.removeAllEnqueuedBuckets()
        
        XCTAssertTrue(bucketQueueHolder.allEnqueuedBuckets.isEmpty)
    }
}

