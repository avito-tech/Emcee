import BalancingBucketQueue
import BucketQueue
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import TestHelpers
import XCTest

final class MultipleQueuesBucketResultAccepterTests: XCTestCase {
    private lazy var multipleQueuesContainer = MultipleQueuesContainer()
    private lazy var multipleQueuesBucketResultAccepter = MultipleQueuesBucketResultAccepter(
        multipleQueuesContainer: multipleQueuesContainer
    )
    
    func test___accepting_without_jobs___throws() {
        assertThrows {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: "worker"
            )
        }
    }
    
    func test___accepting_results_for_known_bucket___in_running_job___does_not_throw() {
        let bucketQueue = FakeBucketQueue()
        
        let jobQueue = createJobQueue(bucketQueue: bucketQueue)
        
        multipleQueuesContainer.add(runningJobQueue: jobQueue)
        
        assertDoesNotThrow {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: WorkerId("worker")
            )
        }
    }
    
    func test___accepting_results_for_known_bucket___in_deleted_job___does_not_throw() {
        let bucketQueue = FakeBucketQueue()
        
        let jobQueue = createJobQueue(bucketQueue: bucketQueue)
        
        multipleQueuesContainer.add(deletedJobQueues: [jobQueue])
        
        assertDoesNotThrow {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: WorkerId("worker")
            )
        }
    }
    
    func test___when_bucket_queue_throws___rethrows() {
        let bucketQueue = FakeBucketQueue(throwsOnAccept: true)
        
        let jobQueue = createJobQueue(bucketQueue: bucketQueue)
        
        multipleQueuesContainer.add(runningJobQueue: jobQueue)
        
        assertThrows {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: "worker"
            )
        }
    }
}

