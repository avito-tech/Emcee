import BalancingBucketQueue
import BucketQueue
import BucketQueueTestHelpers
import QueueModelsTestHelpers
import Foundation
import XCTest

final class MultipleQueuesDequeueableBucketSourceTests: XCTestCase {
    lazy var nothingToDequeueBehavior = FakeNothingToDequeueBehavior()
    lazy var multipleQueuesContainer = MultipleQueuesContainer()
    lazy var multipleQueuesDequeueableBucketSource =  MultipleQueuesDequeueableBucketSource(
        multipleQueuesContainer: multipleQueuesContainer,
        nothingToDequeueBehavior: nothingToDequeueBehavior
    )
    
    func test___nothing_to_dequeue() {
        let dequeueResult = multipleQueuesDequeueableBucketSource.dequeueBucket(
            requestId: "request",
            workerCapabilities: [],
            workerId: "worker"
        )
        XCTAssertEqual(
            dequeueResult,
            nothingToDequeueBehavior.dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: [])
        )
    }
    
    func test___dequeueing() {
        let expectedDequeueResult = DequeueResult.dequeuedBucket(
            DequeuedBucket(
                enqueuedBucket: EnqueuedBucket(
                    bucket: BucketFixtures.createBucket(),
                    enqueueTimestamp: Date(),
                    uniqueIdentifier: "id"
                ),
                workerId: "worker",
                requestId: "request"
            )
        )
        
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: expectedDequeueResult)
        multipleQueuesContainer.add(runningJobQueue: createJobQueue(bucketQueue: bucketQueue))
        
        let dequeueResult = multipleQueuesDequeueableBucketSource.dequeueBucket(
            requestId: "request",
            workerCapabilities: [],
            workerId: "worker"
        )
        
        XCTAssertEqual(dequeueResult, expectedDequeueResult)
    }
    
    func test___dequeueing_already_dequeued_bucket() {
        let bucketQueue = FakeBucketQueue()
        let dequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(
                bucket: BucketFixtures.createBucket(),
                enqueueTimestamp: Date(),
                uniqueIdentifier: "id"
            ),
            workerId: "worker",
            requestId: "request"
        )
        bucketQueue.fixedPreviouslyDequeuedBucket = dequeuedBucket
        multipleQueuesContainer.add(runningJobQueue: createJobQueue(bucketQueue: bucketQueue))
        
        let dequeueResult = multipleQueuesDequeueableBucketSource.dequeueBucket(
            requestId: "request",
            workerCapabilities: [],
            workerId: "worker"
        )
        
        XCTAssertEqual(
            dequeueResult,
            .dequeuedBucket(dequeuedBucket)
        )
    }
    
    func test___querying_for_previously_dequeued() {
        let bucketQueue = FakeBucketQueue()
        bucketQueue.fixedPreviouslyDequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(
                bucket: BucketFixtures.createBucket(),
                enqueueTimestamp: Date(),
                uniqueIdentifier: "id"
            ),
            workerId: "worker",
            requestId: "request"
        )
        multipleQueuesContainer.add(runningJobQueue: createJobQueue(bucketQueue: bucketQueue))
        
        XCTAssertEqual(
            multipleQueuesDequeueableBucketSource.previouslyDequeuedBucket(
                requestId: "request",
                workerId: "worker"
            ),
            bucketQueue.fixedPreviouslyDequeuedBucket
        )
    }
}

final class FakeNothingToDequeueBehavior: NothingToDequeueBehavior {
    var result: DequeueResult = .queueIsEmpty

    func dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: [DequeueResult]) -> DequeueResult {
        result
    }
}
