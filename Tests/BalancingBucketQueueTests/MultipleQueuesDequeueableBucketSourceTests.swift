import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import QueueModelsTestHelpers
import Foundation
import XCTest

final class MultipleQueuesDequeueableBucketSourceTests: XCTestCase {
    lazy var multipleQueuesContainer = MultipleQueuesContainer()
    lazy var multipleQueuesDequeueableBucketSource =  MultipleQueuesDequeueableBucketSource(
        multipleQueuesContainer: multipleQueuesContainer
    )
    
    func test___nothing_to_dequeue() {
        let dequeuedBucket = multipleQueuesDequeueableBucketSource.dequeueBucket(
            workerCapabilities: [],
            workerId: "worker"
        )
        XCTAssertNil(dequeuedBucket)
    }
    
    func test___dequeueing() {
        let expectedDequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(
                bucket: BucketFixtures.createBucket(),
                enqueueTimestamp: Date(),
                uniqueIdentifier: "id"
            ),
            workerId: "worker"
        )
        
        let bucketQueue = FakeBucketQueue(fixedDequeuedBucket: expectedDequeuedBucket)
        multipleQueuesContainer.add(runningJobQueue: createJobQueue(bucketQueue: bucketQueue))
        
        let dequeuedBucket = multipleQueuesDequeueableBucketSource.dequeueBucket(
            workerCapabilities: [],
            workerId: "worker"
        )
        
        XCTAssertEqual(dequeuedBucket, expectedDequeuedBucket)
    }
}
