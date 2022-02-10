import BalancingBucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import QueueModelsTestHelpers
import TestHelpers
import Foundation
import XCTest

final class MultipleQueuesStuckBucketsReenqueuerTests: XCTestCase {
    lazy var multipleQueuesContainer = MultipleQueuesContainer()
    lazy var stuckBucketsReenqueuerProvider = FakeStuckBucketsReenqueuerProvider()
    lazy var multipleQueuesStuckBucketsReenqueuer = MultipleQueuesStuckBucketsReenqueuer(
        multipleQueuesContainer: multipleQueuesContainer,
        stuckBucketsReenqueuerProvider: stuckBucketsReenqueuerProvider
    )
    
    func test() {
        let stuckBucket = StuckBucket(
            reason: .bucketLost,
            bucket: BucketFixtures().bucket(),
            workerId: "worker"
        )
        multipleQueuesContainer.add(runningJobQueue: createJobQueue())
        
        stuckBucketsReenqueuerProvider.fakeStuckBucketsReenqueuer.result = {
            [stuckBucket]
        }
        
        XCTAssertEqual(
            try multipleQueuesStuckBucketsReenqueuer.reenqueueStuckBuckets(),
            [stuckBucket]
        )
    }
    
    func test___rethrows() {
        multipleQueuesContainer.add(runningJobQueue: createJobQueue())
        
        stuckBucketsReenqueuerProvider.fakeStuckBucketsReenqueuer.result = {
            throw ErrorForTestingPurposes()
        }
        
        assertThrows {
            try multipleQueuesStuckBucketsReenqueuer.reenqueueStuckBuckets()
        }
    }
}
