import BucketQueue
import Foundation
import Models
import ModelsTestHelpers
import WorkerAlivenessTracker
import WorkerAlivenessTrackerTestHelpers
import XCTest

final class BucketQueueRetryTests: XCTestCase {
    func test___bucket_queue___gives_job_to_another_worker___if_worker_fails() {
        assertNoThrow {
            // Given
            let bucketQueue = self.bucketQueue(workerIds: [failingWorker, anotherWorker], numberOfRetries: 2)
            
            bucketQueue.enqueue(buckets: [testingResultFixtures.bucket])
            
            // When worker fails
            try dequeueTestAndFail(bucketQueue: bucketQueue, workerId: failingWorker)
            
            // Then we give work to another worker
            XCTAssertEqual(
                bucketQueue.dequeueBucket(requestId: "1", workerId: failingWorker),
                DequeueResult.nothingToDequeueAtTheMoment
            )
            
            XCTAssertEqual(
                bucketQueue.dequeueBucket(requestId: "2", workerId: anotherWorker),
                DequeueResult.dequeuedBucket(
                    DequeuedBucket(
                        bucket: testingResultFixtures.bucket,
                        workerId: anotherWorker,
                        requestId: "2"
                    )
                )
            )
        }
    }
    
    func test___bucket_queue___gives_job_to_any_worker___if_all_workers_fail() {
        assertNoThrow {
            // Given
            let allWorkers = [firstWorker, secondWorker]
            let bucketQueue = self.bucketQueue(workerIds: allWorkers, numberOfRetries: 2)
            
            bucketQueue.enqueue(buckets: [testingResultFixtures.bucket])
            
            // When all workers fail
            try allWorkers.forEach { workerId in
                try dequeueTestAndFail(bucketQueue: bucketQueue, workerId: workerId)
            }
            
            // Then any of them can take work
            let anyWorker = firstWorker
            XCTAssertEqual(
                bucketQueue.dequeueBucket(requestId: "other", workerId: anyWorker),
                DequeueResult.dequeuedBucket(
                    DequeuedBucket(
                        bucket: testingResultFixtures.bucket,
                        workerId: anyWorker,
                        requestId: "other"
                    )
                )
            )
        }
    }
    
    func test___bucket_queue___become_depleted___after_retries() {
        assertNoThrow {
            // Given
            let bucketQueue = self.bucketQueue(workerIds: [firstWorker, secondWorker], numberOfRetries: 2)
            
            bucketQueue.enqueue(buckets: [testingResultFixtures.bucket])
            
            // When retry limit is reached
            try [firstWorker, secondWorker, firstWorker].forEach { workerId in
                try dequeueTestAndFail(bucketQueue: bucketQueue, workerId: workerId)
            }
            
            // Then queue is empty
            let anyWorker = firstWorker
            XCTAssertEqual(
                bucketQueue.dequeueBucket(requestId: "other", workerId: anyWorker),
                DequeueResult.queueIsEmpty
            )
        }
    }
    
    private let firstWorker = "firstWorker"
    private let secondWorker = "secondWorker"
    private let failingWorker = "failingWorker"
    private let anotherWorker = "anotherWorker"
    
    private func bucketQueue(workerIds: [String], numberOfRetries: Int) -> BucketQueue {
        let tracker = WorkerAlivenessTrackerFixtures.alivenessTrackerWithAlwaysAliveResults()
        workerIds.forEach(tracker.didRegisterWorker)
        
        let bucketQueue = BucketQueueFixtures.bucketQueue(
            workerAlivenessProvider: tracker,
            testHistoryTracker: TestHistoryTrackerFixtures.testHistoryTracker(
                numberOfRetries: 2
            )
        )
        
        return bucketQueue
    }
    
    private func dequeueTestAndFail(bucketQueue: BucketQueue, workerId: String) throws {
        let requestId = UUID().uuidString
        
        _ = bucketQueue.dequeueBucket(
            requestId: requestId,
            workerId: workerId
        )
        
        _ = try bucketQueue.accept(
            testingResult: testingResultFixtures.testingResult(),
            requestId: requestId,
            workerId: workerId
        )
    }
    
    private let testingResultFixtures: TestingResultFixtures = TestingResultFixtures()
        .addingResult(success: false)
    
    private func assertNoThrow(file: StaticString = #file, line: UInt = #line, body: () throws -> ()) {
        do {
            try body()
        } catch let e {
            XCTFail("Unexpectidly caught \(e)", file: file, line: line)
        }
    }
}
