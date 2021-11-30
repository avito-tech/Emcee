import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import TestHelpers
import XCTest

final class MultipleQueuesBucketResultAccepterTests: XCTestCase {
    private lazy var bucketResultAccepterProvider = FakeBucketResultAccepterProvider()
    private lazy var multipleQueuesContainer = MultipleQueuesContainer()
    private lazy var multipleQueuesBucketResultAccepter = MultipleQueuesBucketResultAccepter(
        bucketResultAccepterProvider: bucketResultAccepterProvider,
        multipleQueuesContainer: multipleQueuesContainer
    )
    private lazy var workerId = WorkerId("worker")
    
    func test___accepting_results___rethrows___if_accepter_throws() {
        bucketResultAccepterProvider.resultProvider = { _, _, _ in
            throw ErrorForTestingPurposes()
        }
        
        assertThrows {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: workerId
            )
        }
    }
    
    
    func test___accepting_results___in_running_job___does_not_throw___if_accepter_does_not_throw() {
        let jobQueue = createJobQueue()
        multipleQueuesContainer.add(runningJobQueue: jobQueue)
        
        let acceptanceRoutineInvoked = XCTestExpectation()

        bucketResultAccepterProvider.resultProvider = { bucketId, testingResult, workerId in
            assertTrue { workerId == self.workerId }
            
            acceptanceRoutineInvoked.fulfill()
            
            return BucketQueueAcceptResult(
                dequeuedBucket: DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: BucketFixtures.createBucket(bucketId: "bucket_id"),
                        enqueueTimestamp: Date(),
                        uniqueIdentifier: "doesnotmatter"
                    ),
                    workerId: self.workerId
                ),
                testingResultToCollect: testingResult
            )
        }
        
        assertDoesNotThrow {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: workerId
            )
        }
                
        wait(for: [acceptanceRoutineInvoked], timeout: 15)
    }
    
    
    func test___accepting_results___in_deleted_job___does_not_throw___if_accepter_does_not_throw() {
        let jobQueue = createJobQueue()
        multipleQueuesContainer.add(deletedJobQueues: [jobQueue])
        
        let acceptanceRoutineInvoked = XCTestExpectation()

        bucketResultAccepterProvider.resultProvider = { bucketId, testingResult, workerId in
            assertTrue { workerId == self.workerId }
            
            acceptanceRoutineInvoked.fulfill()
            
            return BucketQueueAcceptResult(
                dequeuedBucket: DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: BucketFixtures.createBucket(bucketId: "bucket_id"),
                        enqueueTimestamp: Date(),
                        uniqueIdentifier: "doesnotmatter"
                    ),
                    workerId: self.workerId
                ),
                testingResultToCollect: testingResult
            )
        }
        
        assertDoesNotThrow {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: workerId
            )
        }
                
        wait(for: [acceptanceRoutineInvoked], timeout: 15)
    }
    
    func test___accepting_unknown_bucket___throws() {
        assertThrows {
            _ = try multipleQueuesBucketResultAccepter.accept(
                bucketId: "bucket_id",
                testingResult: TestingResultFixtures().testingResult(),
                workerId: "worker"
            )
        }
    }
}

