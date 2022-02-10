import BalancingBucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import QueueModels
import QueueModelsTestHelpers
import Foundation
import WorkerCapabilitiesModels
import XCTest

final class MultipleQueuesDequeueableBucketSourceTests: XCTestCase {
    lazy var multipleQueuesContainer = MultipleQueuesContainer()
    lazy var dequeueableBucketSourceProvider = FakeDequeueableBucketSourceProvider()
    lazy var multipleQueuesDequeueableBucketSource = MultipleQueuesDequeueableBucketSource(
        dequeueableBucketSourceProvider: dequeueableBucketSourceProvider,
        multipleQueuesContainer: multipleQueuesContainer
    )
    
    func test___nothing_to_dequeue() {
        dequeueableBucketSourceProvider.fakeDequeueableBucketSource.result = { _, _ in
            nil
        }
        
        let dequeuedBucket = multipleQueuesDequeueableBucketSource.dequeueBucket(
            workerCapabilities: [],
            workerId: "worker"
        )
        XCTAssertNil(dequeuedBucket)
    }
    
    func test___dequeueing() {
        let expectedDequeuedBucket = DequeuedBucket(
            enqueuedBucket: EnqueuedBucket(
                bucket: BucketFixtures().bucket(),
                enqueueTimestamp: Date(),
                uniqueIdentifier: "id"
            ),
            workerId: "worker"
        )
        dequeueableBucketSourceProvider.fakeDequeueableBucketSource.result = { _, _ in
            expectedDequeuedBucket
        }
        
        multipleQueuesContainer.add(runningJobQueue: createJobQueue())
        
        let dequeuedBucket = multipleQueuesDequeueableBucketSource.dequeueBucket(
            workerCapabilities: [],
            workerId: "worker"
        )
        
        XCTAssertEqual(dequeuedBucket, expectedDequeuedBucket)
    }
}
