import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
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
                workerId: "worker"            )
        )
        
        let bucketQueue = FakeBucketQueue(fixedDequeueResult: expectedDequeueResult)
        multipleQueuesContainer.add(runningJobQueue: createJobQueue(bucketQueue: bucketQueue))
        
        let dequeueResult = multipleQueuesDequeueableBucketSource.dequeueBucket(
            workerCapabilities: [],
            workerId: "worker"
        )
        
        XCTAssertEqual(dequeueResult, expectedDequeueResult)
    }
}

final class FakeNothingToDequeueBehavior: NothingToDequeueBehavior {
    var result: DequeueResult = .queueIsEmpty

    func dequeueResultWhenNoBucketsToDequeueAvaiable(dequeueResults: [DequeueResult]) -> DequeueResult {
        result
    }
}
