import BalancingBucketQueue
import BucketQueue
import BucketQueueModels
import BucketQueueTestHelpers
import CommonTestModelsTestHelpers
import Foundation
import QueueModels
import QueueModelsTestHelpers
import TestHelpers
import XCTest

final class MultipleQueuesBucketResultAcceptorTests: XCTestCase {
    private lazy var bucketResultAcceptorProvider = FakeBucketResultAcceptorProvider()
    private lazy var multipleQueuesContainer = MultipleQueuesContainer()
    private lazy var multipleQueuesBucketResultAcceptor = MultipleQueuesBucketResultAcceptor(
        bucketResultAcceptorProvider: bucketResultAcceptorProvider,
        multipleQueuesContainer: multipleQueuesContainer
    )
    private lazy var workerId = WorkerId("worker")
    
    func test___accepting_results___rethrows___if_accepter_throws() {
        bucketResultAcceptorProvider.resultProvider = { _, _, _ in
            throw ErrorForTestingPurposes()
        }
        
        assertThrows {
            _ = try multipleQueuesBucketResultAcceptor.accept(
                bucketId: "bucket_id",
                bucketResult: .testingResult(
                    TestingResultFixtures().testingResult()
                ),
                workerId: workerId
            )
        }
    }
    
    
    func test___accepting_results___in_running_job___does_not_throw___if_accepter_does_not_throw() {
        let jobQueue = createJobQueue()
        multipleQueuesContainer.add(runningJobQueue: jobQueue)
        
        let acceptanceRoutineInvoked = XCTestExpectation()

        bucketResultAcceptorProvider.resultProvider = { bucketId, bucketResult, workerId in
            assertTrue { workerId == self.workerId }
            
            acceptanceRoutineInvoked.fulfill()
            
            return BucketQueueAcceptResult(
                dequeuedBucket: DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: BucketFixtures().with(bucketId: "bucket_id").bucket(),
                        enqueueTimestamp: Date(),
                        uniqueIdentifier: "doesnotmatter"
                    ),
                    workerId: self.workerId
                ),
                bucketResultToCollect: bucketResult
            )
        }
        
        assertDoesNotThrow {
            _ = try multipleQueuesBucketResultAcceptor.accept(
                bucketId: "bucket_id",
                bucketResult: .testingResult(TestingResultFixtures().testingResult()),
                workerId: workerId
            )
        }
                
        wait(for: [acceptanceRoutineInvoked], timeout: 15)
    }
    
    
    func test___accepting_results___in_deleted_job___does_not_throw___if_accepter_does_not_throw() {
        let jobQueue = createJobQueue()
        multipleQueuesContainer.add(deletedJobQueues: [jobQueue])
        
        let acceptanceRoutineInvoked = XCTestExpectation()

        bucketResultAcceptorProvider.resultProvider = { bucketId, bucketResult, workerId in
            assertTrue { workerId == self.workerId }
            
            acceptanceRoutineInvoked.fulfill()
            
            return BucketQueueAcceptResult(
                dequeuedBucket: DequeuedBucket(
                    enqueuedBucket: EnqueuedBucket(
                        bucket: BucketFixtures().with(bucketId: "bucket_id").bucket(),
                        enqueueTimestamp: Date(),
                        uniqueIdentifier: "doesnotmatter"
                    ),
                    workerId: self.workerId
                ),
                bucketResultToCollect: bucketResult
            )
        }
        
        assertDoesNotThrow {
            _ = try multipleQueuesBucketResultAcceptor.accept(
                bucketId: "bucket_id",
                bucketResult: .testingResult(TestingResultFixtures().testingResult()),
                workerId: workerId
            )
        }
                
        wait(for: [acceptanceRoutineInvoked], timeout: 15)
    }
    
    func test___accepting_unknown_bucket___throws() {
        assertThrows {
            _ = try multipleQueuesBucketResultAcceptor.accept(
                bucketId: "bucket_id",
                bucketResult: .testingResult(TestingResultFixtures().testingResult()),
                workerId: "worker"
            )
        }
    }
}

